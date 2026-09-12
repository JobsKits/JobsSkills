#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
require "set"
require_relative "jobs_swift_ownership"

EXCLUDED_COMPONENTS = %w[
  .git .build .dart_tool Pods ManualBySwiftPods@Pods build DerivedData generated
].freeze
EXCLUDED_COMPONENT_FRAGMENTS = %w[
  GeneratedPluginRegistrant Il2CppOutputProject
].freeze
FACTORY_COMPONENTS = %w[
  JobsSwiftDSL@Pods JobsByUIKit@Pods
].freeze
SYSTEM_CLASS_PREFIX = /\A(?:NS|UI|CA|AV|WK|MK|CL|UN|CN|PH|MF|MTK|CI|GC|LA|AR|SK|SCN|VN|NE|NW|HM|EK|MP|PK|CB|QL|SF|RP|IN|BG|MX|DC|ML|CP|HK|AC|JS|PDF)/
SWIFT_SYSTEM_CLASSES = %w[
  ByteCountFormatter DateComponentsFormatter DateFormatter EnergyFormatter
  ISO8601DateFormatter JSONDecoder JSONEncoder LengthFormatter ListFormatter
  MassFormatter MeasurementFormatter NumberFormatter PersonNameComponentsFormatter
  PropertyListDecoder PropertyListEncoder RelativeDateTimeFormatter
].freeze

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) ||
      EXCLUDED_COMPONENT_FRAGMENTS.any? { |fragment| component.include?(fragment) }
  end
end

def factory_layer?(path)
  path.each_filename.any? { |component| FACTORY_COMPONENTS.include?(component) } ||
    path.basename.to_s.end_with?("+Make.swift")
end

def source_files(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.swift"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end

def mask_comments_and_literals(source)
  bytes = source.b
  masked = bytes.dup
  index = 0
  state = :code
  multiline_hashes = 0
  while index < bytes.bytesize
    current = bytes.getbyte(index)
    following = index + 1 < bytes.bytesize ? bytes.getbyte(index + 1) : nil
    case state
    when :code
      if current == 47 && following == 47
        masked[index, 2] = "  "; index += 2; state = :line_comment
      elsif current == 47 && following == 42
        masked[index, 2] = "  "; index += 2; state = :block_comment
      elsif (delimiter = bytes.byteslice(index, 24).to_s.match(/\A(\#+)?"""/n))
        length = delimiter[0].bytesize
        multiline_hashes = delimiter[1].to_s.bytesize
        masked[index, length] = " " * length; index += length; state = :multiline_string
      elsif current == 34
        masked.setbyte(index, 32); index += 1; state = :string
      else
        index += 1
      end
    when :line_comment
      if current == 10
        index += 1; state = :code
      else
        masked.setbyte(index, 32); index += 1
      end
    when :block_comment
      if current == 42 && following == 47
        masked[index, 2] = "  "; index += 2; state = :code
      else
        masked.setbyte(index, 32) unless current == 10; index += 1
      end
    when :string
      if current == 92
        masked.setbyte(index, 32); index += 1
        if index < bytes.bytesize
          masked.setbyte(index, 32) unless bytes.getbyte(index) == 10
          index += 1
        end
      elsif current == 34
        masked.setbyte(index, 32); index += 1; state = :code
      else
        masked.setbyte(index, 32) unless current == 10; index += 1
      end
    when :multiline_string
      terminal = '"""' + ('#' * multiline_hashes)
      if bytes.byteslice(index, terminal.bytesize) == terminal
        masked[index, terminal.bytesize] = " " * terminal.bytesize
        index += terminal.bytesize; state = :code
      else
        masked.setbyte(index, 32) unless current == 10; index += 1
      end
    end
  end
  masked
end

def sdk_classes(sdk_root)
  classes = Set.new
  Dir.glob(File.join(sdk_root, "System/Library/Frameworks/**/*.h")).sort.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    source.scan(/@interface\s+([A-Z][A-Za-z0-9_]*)\b/) do |match|
      classes << match.first if match.first.match?(SYSTEM_CLASS_PREFIX)
    end
  end
  classes.merge(SWIFT_SYSTEM_CLASSES)
  classes
end

def matching_parenthesis(source, opening)
  depth = 0
  cursor = opening
  while cursor < source.bytesize
    case source.getbyte(cursor)
    when 40 then depth += 1
    when 41
      depth -= 1
      return cursor if depth.zero?
    end
    cursor += 1
  end
  nil
end

def line_number(source, offset)
  source.byteslice(0...offset).count("\n") + 1
end

options = { sdk_root: nil, include_factory_layer: false }
OptionParser.new do |parser|
  parser.banner = "Usage: audit_swift_system_class_construction.rb --sdk-root PATH [PATH...]"
  parser.on("--sdk-root PATH", "iPhoneOS/iPhoneSimulator SDK root") { |path| options[:sdk_root] = path }
  parser.on("--include-factory-layer", "Also print allowed raw construction inside Jobs factories") do
    options[:include_factory_layer] = true
  end
end.parse!
abort "--sdk-root is required" unless options[:sdk_root]
roots = ARGV.empty? ? ["."] : ARGV
classes = sdk_classes(File.expand_path(options[:sdk_root]))
abort "No Swift/Objective-C system classes found under SDK root" if classes.empty?

issues = []
factory_hits = 0
scanned = 0
source_files(roots).each do |path|
  source = File.binread(path)
  utf8_source = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8_source.valid_encoding? && JobsSwiftOwnership.jobs_owned_file?(path, utf8_source)
  scanned += 1
  masked = mask_comments_and_literals(source)
  masked.to_enum(:scan, /(?<![A-Za-z0-9_])([A-Z][A-Za-z0-9_]*)\s*(?:<[^>\n]+>)?\s*\(/).each do
    match = Regexp.last_match
    type = match[1]
    next unless classes.include?(type)
    prefix = masked.byteslice([match.begin(0) - 24, 0].max...[match.begin(0), 0].max).to_s
    next if prefix.match?(/\b(?:func|class|struct|enum|protocol|typealias)\s*\z/)
    opening = masked.index("(", match.begin(1) + type.bytesize)
    closing = opening && matching_parenthesis(masked, opening)
    next unless closing
    arguments = masked.byteslice((opening + 1)...closing).strip
    snippet = source.byteslice(match.begin(0), [closing - match.begin(0) + 1, 160].min)
                    .force_encoding(Encoding::UTF_8).scrub.gsub(/\s+/, " ").strip
    if factory_layer?(Pathname(path))
      factory_hits += 1
      next unless options[:include_factory_layer]
      status = "factory-layer"
    else
      status = arguments.empty? ? "zero-argument" : "parameterized"
      issues << [path, match.begin(0)]
    end
    puts [status, path, line_number(source, match.begin(0)), type, snippet].join("\t")
  end
end

puts "issues=#{issues.length} issue_files=#{issues.map(&:first).uniq.length} factory_hits=#{factory_hits} scanned=#{scanned} sdk_classes=#{classes.length}"
exit(issues.empty? ? 0 : 2)
