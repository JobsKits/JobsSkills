#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
require "set"
require_relative "jobs_oc_ownership"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData generated
].freeze
EXCLUDED_COMPONENT_FRAGMENTS = %w[
  Manual_Add_ThirdParty GeneratedPluginRegistrant Il2CppOutputProject
].freeze
FACTORY_COMPONENTS = %w[
  JobsMakes@Pods JobsOCDSL@Pods
].freeze
SYSTEM_CLASS_PREFIX = /\A(?:NS|UI|CA|AV|WK|MK|CL|UN|CN|PH|MF|MTK|CI|GC|LA|AR|SK|SCN|VN|NE|NW|HM|EK|MP|PK|CB|QL|SF|RP|IN|BG|MX|DC|ML|CP|HK|AC|JS|PDF)/

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) ||
      EXCLUDED_COMPONENT_FRAGMENTS.any? { |fragment| component.include?(fragment) }
  end
end

def factory_layer?(path)
  path.each_filename.any? { |component| FACTORY_COMPONENTS.include?(component) } ||
    path.basename.to_s == "JobsMakes.h" || path.basename.to_s.include?("+DSL")
end

def category_factory_hit?(path, source, offset, type)
  return false unless path.basename.to_s.start_with?("#{type}+")

  prefix = source.byteslice(0...offset).force_encoding(Encoding::UTF_8)
  return false unless prefix.valid_encoding?

  current_method = nil
  prefix.each_line do |line|
    match = line.match(/^\s*([+-])\s*\([^)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)/)
    current_method = [match[1], match[2]] if match
  end
  current_method&.first == "+" && current_method&.last&.start_with?("initBy")
end

def source_files(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{h,m,mm}"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end

def mask_comments_and_literals(source)
  bytes = source.b
  masked = bytes.dup
  index = 0
  state = :code
  while index < bytes.bytesize
    current = bytes.getbyte(index)
    following = index + 1 < bytes.bytesize ? bytes.getbyte(index + 1) : nil
    case state
    when :code
      if current == 47 && following == 47
        masked[index, 2] = "  "; index += 2; state = :line_comment
      elsif current == 47 && following == 42
        masked[index, 2] = "  "; index += 2; state = :block_comment
      elsif current == 34
        masked.setbyte(index, 32); index += 1; state = :string
      elsif current == 39
        masked.setbyte(index, 32); index += 1; state = :character
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
    when :string, :character
      terminal = state == :string ? 34 : 39
      if current == 92
        masked.setbyte(index, 32); index += 1
        if index < bytes.bytesize
          masked.setbyte(index, 32) unless bytes.getbyte(index) == 10
          index += 1
        end
      elsif current == terminal
        masked.setbyte(index, 32); index += 1; state = :code
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
  classes
end

def line_number(source, offset)
  source.byteslice(0...offset).count("\n") + 1
end

options = { sdk_root: nil, include_factory_layer: false }
OptionParser.new do |parser|
  parser.banner = "Usage: audit_oc_system_class_construction.rb --sdk-root PATH [PATH...]"
  parser.on("--sdk-root PATH", "iPhoneOS/iPhoneSimulator SDK root") { |path| options[:sdk_root] = path }
  parser.on("--include-factory-layer", "Also print allowed raw construction inside Jobs factories") do
    options[:include_factory_layer] = true
  end
end.parse!
abort "--sdk-root is required" unless options[:sdk_root]
roots = ARGV.empty? ? ["."] : ARGV
classes = sdk_classes(File.expand_path(options[:sdk_root]))
abort "No Objective-C system classes found under SDK root" if classes.empty?

issues = []
factory_hits = 0
scanned = 0
source_files(roots).each do |path|
  source = File.binread(path)
  utf8_source = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8_source.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, utf8_source)
  scanned += 1
  masked = mask_comments_and_literals(source)
  hits = []
  patterns = [
    /\b([A-Z][A-Za-z0-9_]*)\s*\.\s*new\b/,
    /\[\s*([A-Z][A-Za-z0-9_]*)\s+new\s*\]/,
    /\b([A-Z][A-Za-z0-9_]*)\s*\.\s*alloc\s*\.\s*init(?:With[A-Z][A-Za-z0-9_]*)?\b/,
    /\[\s*([A-Z][A-Za-z0-9_]*)\s*\.\s*alloc\s+init(?:With[A-Z][A-Za-z0-9_]*)?\b/,
    /\[\s*\[\s*([A-Z][A-Za-z0-9_]*)\s+alloc\s*\]\s+init(?:With[A-Z][A-Za-z0-9_]*)?\b/
  ]
  patterns.each do |pattern|
    masked.to_enum(:scan, pattern).each do
      match = Regexp.last_match
      type = match[1]
      next unless classes.include?(type)
      next if hits.any? { |hit| hit[:offset] == match.begin(0) && hit[:type] == type }
      snippet = source.byteslice(match.begin(0), [match[0].bytesize + 48, source.bytesize - match.begin(0)].min)
                      .force_encoding(Encoding::UTF_8).scrub.lines.first.to_s.strip
      parameterized = match[0].include?("initWith")
      hits << { offset: match.begin(0), type: type, parameterized: parameterized, snippet: snippet }
    end
  end
  hits.sort_by { |hit| hit[:offset] }.each do |hit|
    if factory_layer?(Pathname(path)) || category_factory_hit?(Pathname(path), source, hit[:offset], hit[:type])
      factory_hits += 1
      next unless options[:include_factory_layer]
      status = "factory-layer"
    else
      status = hit[:parameterized] ? "parameterized" : "zero-argument"
      issues << [path, hit]
    end
    puts [status, path, line_number(source, hit[:offset]), hit[:type], hit[:snippet]].join("\t")
  end
end

puts "issues=#{issues.length} issue_files=#{issues.map(&:first).uniq.length} factory_hits=#{factory_hits} scanned=#{scanned} sdk_classes=#{classes.length}"
exit(issues.empty? ? 0 : 2)
