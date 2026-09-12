#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "pathname"
require "set"
require "optparse"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze
SYSTEM_NONBLOCK_METHOD_SELECTORS = Set.new(%w[resume]).freeze
SYSTEM_NONBLOCK_PROPERTIES = Set.new(%w[lightTextColor systemVersion]).freeze

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) || component.include?("Manual_Add_ThirdParty")
  end
end


def source_files(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{h,m,mm}"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end

def mask_non_code(source)
  bytes = source.b
  masked = bytes.dup
  index = 0
  state = :code
  while index < bytes.length
    current = bytes[index]
    following = index + 1 < bytes.length ? bytes[index + 1] : nil
    case state
    when :code
      if current == "/" && following == "/"
        masked[index, 2] = "  "
        index += 2
        state = :line_comment
      elsif current == "/" && following == "*"
        masked[index, 2] = "  "
        index += 2
        state = :block_comment
      elsif current == '"'
        masked.setbyte(index, 32)
        index += 1
        state = :string
      elsif current == "'"
        masked.setbyte(index, 32)
        index += 1
        state = :character
      else
        index += 1
      end
    when :line_comment
      if current == "\n"
        index += 1
        state = :code
      else
        masked.setbyte(index, 32)
        index += 1
      end
    when :block_comment
      if current == "*" && following == "/"
        masked[index, 2] = "  "
        index += 2
        state = :code
      else
        masked.setbyte(index, 32) unless current == "\n"
        index += 1
      end
    when :string, :character
      terminal = state == :string ? '"' : "'"
      if current == "\\"
        masked.setbyte(index, 32)
        index += 1
        if index < bytes.length
          masked.setbyte(index, 32) unless bytes[index] == "\n"
          index += 1
        end
      elsif current == terminal
        masked.setbyte(index, 32)
        index += 1
        state = :code
      else
        masked.setbyte(index, 32) unless current == "\n"
        index += 1
      end
    end
  end
  masked
end

def line_number(source, offset)
  source[0...offset].count("\n") + 1
end

def property_name(declaration)
  prefix = declaration.split(/\b(?:API|NS|CF|UIKIT|SWIFT)_[A-Z_]\w*\b/, 2).first
  prefix = prefix.sub(/;.*\z/m, "").rstrip
  block_name = prefix[/\(\s*\^\s*([A-Za-z_]\w*)\s*\)/, 1]
  return block_name if block_name

  prefix[/\b([A-Za-z_]\w*)\s*(?:\[[^\]]*\])?\s*\z/, 1]
end

options = { contract_roots: [] }
OptionParser.new do |parser|
  parser.banner = "Usage: audit_oc_block_call_sites.rb [--contract-root PATH] PATH..."
  parser.on("--contract-root PATH", "Headers that declare system or third-party selectors; repeatable") do |value|
    options[:contract_roots] << value
  end
end.parse!

abort "Usage: audit_oc_block_call_sites.rb [--contract-root PATH] PATH..." if ARGV.empty?

sources = {}
source_files(ARGV).each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  sources[path] = [source, mask_non_code(source)]
end

block_selectors = Set.new
block_property_selectors = Set.new
nonblock_method_selectors = SYSTEM_NONBLOCK_METHOD_SELECTORS.dup
nonblock_properties = SYSTEM_NONBLOCK_PROPERTIES.dup
block_type_names = Set.new(["dispatch_block_t"])
sources.each_value do |source, masked|
  masked.to_enum(:scan, /typedef\b.*?\(\s*\^\s*([A-Za-z_]\w*)\s*\)/m).each do
    block_type_names << Regexp.last_match[1]
  end
end
block_declaration = lambda do |declaration|
  declaration.include?("(^") || declaration.match?(/\b(?:Jobs|jobs)[A-Za-z_]\w*Blocks?\b/) ||
    declaration.scan(/[A-Za-z_]\w*/).any? { |name| block_type_names.include?(name) } ||
    declaration.match?(/\b\w*_block_t\b/)
end

sources.each_value do |source, masked|
  masked.to_enum(:scan, /^[ \t]*[-+][ \t]*\(([^\r\n)]*)\)[ \t]*([A-Za-z_]\w*)\b[^:;{\r\n]*(?:[;{]|\r?$)/m).each do
    match = Regexp.last_match
    return_type = source[match.begin(1)...match.end(1)]
    if block_declaration.call(return_type)
      block_selectors << match[2]
    else
      nonblock_method_selectors << match[2]
    end
  end

  masked.to_enum(:scan, /@property\b[^;]*;/m).each do
    match = Regexp.last_match
    declaration = source[match.begin(0)...match.end(0)]
    name = property_name(declaration)
    next unless name

    if block_declaration.call(declaration)
      block_property_selectors << name
    else
      nonblock_properties << name
    end
  end
  masked.to_enum(:scan, /\bProp_[A-Za-z_]\w*\s*\([^)]*\)[^;]*;/m).each do
    match = Regexp.last_match
    declaration = source[match.begin(0)...match.end(0)]
    name = property_name(declaration)
    next unless name

    if block_declaration.call(declaration)
      block_property_selectors << name
    else
      nonblock_properties << name
    end
  end
end

options[:contract_roots].flat_map do |root|
  expanded = File.expand_path(root)
  File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.h"))
end.uniq.sort.each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding?

  masked = mask_non_code(source)
  masked.to_enum(:scan, /^[ \t]*[-+][ \t]*\(([^\r\n)]*)\)[ \t]*([A-Za-z_]\w*)\b[^:;{\r\n]*(?:[;{]|\r?$)/m).each do
    match = Regexp.last_match
    return_type = source[match.begin(1)...match.end(1)]
    nonblock_method_selectors << match[2] unless block_declaration.call(return_type)
  end
  masked.to_enum(:scan, /@property\b[^;]*;/m).each do
    match = Regexp.last_match
    declaration = source[match.begin(0)...match.end(0)]
    name = property_name(declaration)
    next unless name

    if block_declaration.call(declaration)
      block_property_selectors << name
    else
      nonblock_properties << name
    end
  end
end

exclusive_block_selectors = block_selectors - nonblock_properties - block_property_selectors - nonblock_method_selectors
exclusive_nonblock_properties = nonblock_properties - block_selectors - block_property_selectors
counts = Hash.new(0)
sources.each do |path, (source, masked)|
  unless exclusive_block_selectors.empty?
    masked.to_enum(:scan, /\.\s*([A-Za-z_]\w*)\b(?!\s*\()/).each do
      match = Regexp.last_match
      next unless exclusive_block_selectors.include?(match[1])

      line_start = masked.rindex("\n", match.begin(0))
      line_start = line_start ? line_start + 1 : 0
      line_end = masked.index("\n", match.end(0)) || masked.length
      prefix = masked[line_start...match.begin(0)]
      suffix = masked[match.end(0)...line_end]
      # A Block getter may legitimately be assigned, returned or passed onward.
      # A standalone expression, chained member access, or using the Block as
      # an Objective-C message receiver is an unambiguous missing `()` call.
      standalone = suffix.match?(/\A\s*;/) &&
                   !prefix.include?("=") &&
                   !prefix.match?(/\breturn\b/)
      chained = suffix.match?(/\A\s*\./)
      inside_message = prefix.count("[") > prefix.count("]") &&
                       suffix.match?(/\A\s+[A-Za-z_]\w*(?:\s*:|\s*\])/)
      next unless standalone || chained || inside_message

      counts["missed-block-call"] += 1
      puts ["missed-block-call", path, line_number(source, match.begin(0)), match[1]].join("\t")
    end

  end
  unless exclusive_nonblock_properties.empty?
    masked.to_enum(:scan, /\.\s*([A-Za-z_]\w*)\s*\(\s*\)/).each do
      match = Regexp.last_match
      next unless exclusive_nonblock_properties.include?(match[1])

      counts["called-nonblock-property"] += 1
      puts ["called-nonblock-property", path, line_number(source, match.begin(0)), match[1]].join("\t")
    end
  end
end

warn "#{counts.sort.map { |name, count| "#{name}=#{count}" }.join(' ')} selectors=#{block_selectors.length} block_properties=#{block_property_selectors.length} exclusive_selectors=#{exclusive_block_selectors.length} nonblock_methods=#{nonblock_method_selectors.length} properties=#{nonblock_properties.length} exclusive_properties=#{exclusive_nonblock_properties.length} scanned=#{sources.length}"
exit(counts.values.sum.positive? ? 2 : 0)
