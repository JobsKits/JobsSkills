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
SWIFT_NSOBJECT_CLASSES = %w[
  ByteCountFormatter DateComponentsFormatter DateFormatter EnergyFormatter
  ISO8601DateFormatter LengthFormatter ListFormatter MassFormatter
  MeasurementFormatter NumberFormatter PersonNameComponentsFormatter
  RelativeDateTimeFormatter
].freeze
SPECIAL_FACTORIES = {
  "JSONDecoder" => "make",
  "JSONEncoder" => "make"
}.freeze

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) ||
      EXCLUDED_COMPONENT_FRAGMENTS.any? { |fragment| component.include?(fragment) }
  end
end

def factory_layer?(path)
  path.each_filename.any? { |component| FACTORY_COMPONENTS.include?(component) }
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

def objc_system_classes(sdk_root)
  classes = Set.new(SWIFT_NSOBJECT_CLASSES + SPECIAL_FACTORIES.keys)
  Dir.glob(File.join(sdk_root, "System/Library/Frameworks/**/*.h")).sort.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    source.scan(/@interface\s+([A-Z][A-Za-z0-9_]*)\b/) do |match|
      classes << match.first if match.first.match?(SYSTEM_CLASS_PREFIX)
    end
  end
  classes
end

options = { sdk_root: nil, apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: migrate_swift_zero_argument_system_construction.rb --sdk-root PATH [--apply] [PATH...]"
  parser.on("--sdk-root PATH", "iPhoneOS/iPhoneSimulator SDK root") { |path| options[:sdk_root] = path }
  parser.on("--apply", "Rewrite proven zero-argument constructors") { options[:apply] = true }
end.parse!
abort "--sdk-root is required" unless options[:sdk_root]
roots = ARGV.empty? ? ["."] : ARGV
classes = objc_system_classes(File.expand_path(options[:sdk_root]))

changed = []
replacements = 0
skipped_import = 0
source_files(roots).each do |path|
  pathname = Pathname(path)
  next if factory_layer?(pathname)
  source = File.binread(path)
  utf8_source = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8_source.valid_encoding? && JobsSwiftOwnership.jobs_owned_file?(path, utf8_source)
  masked = mask_comments_and_literals(source)
  edits = []
  masked.to_enum(:scan, /(?<![A-Za-z0-9_])([A-Z][A-Za-z0-9_]*)\s*\(\s*\)/).each do
    match = Regexp.last_match
    type = match[1]
    next unless classes.include?(type)
    same_module = pathname.each_filename.any? { |component| component == "JobsSwiftBlock@Pods" }
    unless same_module || source.match?(/^import\s+(?:JobsSwiftBlock|JobsSwiftBaseDefines|JobsSwiftDSL|JobsByUIKit)\s*$/)
      skipped_import += 1
      next
    end
    factory = SPECIAL_FACTORIES.fetch(type, "jobsMake")
    start_offset = match.begin(0)
    end_offset = match.end(0)
    original_slice = source.byteslice(start_offset, end_offset - start_offset)
    unless original_slice&.match?(/\A#{Regexp.escape(type)}\s*\(\s*\)\z/n)
      abort "unsafe byte offset: #{path}:#{start_offset}: #{original_slice.inspect}"
    end
    edits << [start_offset, end_offset, "#{type}.#{factory} { _ in }"]
  end
  next if edits.empty?
  changed << path
  replacements += edits.length
  puts [options[:apply] ? "updated" : "candidate", path, edits.length].join("\t")
  next unless options[:apply]
  updated = source.dup
  edits.reverse_each { |start_offset, end_offset, replacement| updated[start_offset...end_offset] = replacement }
  edits.each do |_start_offset, _end_offset, replacement|
    abort "replacement missing after rewrite: #{path}: #{replacement}" unless updated.include?(replacement)
  end
  File.binwrite(path, updated)
end

puts "changed_files=#{changed.length} replacements=#{replacements} skipped_import=#{skipped_import} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
