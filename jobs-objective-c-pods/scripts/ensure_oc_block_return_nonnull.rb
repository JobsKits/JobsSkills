#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"
require "set"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

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
        masked[index, 2] = "  "; index += 2; state = :line_comment
      elsif current == "/" && following == "*"
        masked[index, 2] = "  "; index += 2; state = :block_comment
      elsif current == '"'
        masked.setbyte(index, 32); index += 1; state = :string
      elsif current == "'"
        masked.setbyte(index, 32); index += 1; state = :character
      else
        index += 1
      end
    when :line_comment
      if current == "\n"
        index += 1; state = :code
      else
        masked.setbyte(index, 32); index += 1
      end
    when :block_comment
      if current == "*" && following == "/"
        masked[index, 2] = "  "; index += 2; state = :code
      else
        masked.setbyte(index, 32) unless current == "\n"; index += 1
      end
    when :string, :character
      terminal = state == :string ? '"' : "'"
      if current == "\\"
        masked.setbyte(index, 32); index += 1
        if index < bytes.length
          masked.setbyte(index, 32) unless bytes[index] == "\n"; index += 1
        end
      elsif current == terminal
        masked.setbyte(index, 32); index += 1; state = :code
      else
        masked.setbyte(index, 32) unless current == "\n"; index += 1
      end
    end
  end
  masked
end

def block_return?(return_type)
  return_type.match?(/\b(?:Jobs|jobs)[A-Za-z_]\w*Blocks?\b/) ||
    return_type.match?(/\b\w+_block_t\b/)
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: ensure_oc_block_return_nonnull.rb [--apply] PATH..."
  parser.on("--apply", "Add explicit _Nonnull to Objective-C methods returning Blocks") { options[:apply] = true }
end.parse!

abort "At least one path is required" if ARGV.empty?

owned_sources = {}
source_files(ARGV).each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  owned_sources[path] = source
end

explicit_nullable_block_getter_names = Set.new
owned_sources.each_value do |source|
  masked = mask_non_code(source)
  masked.to_enum(:scan, /^[ \t]*[+-][ \t]*\(([^\r\n()]*)\)[ \t]*([A-Za-z_]\w*)/m).each do
    match = Regexp.last_match
    return_type = source[match.begin(1)...match.end(1)]
    next unless block_return?(return_type) && return_type.match?(/\b_Nullable\b/)

    explicit_nullable_block_getter_names << match[2]
  end
end

normalized_property_files = 0
normalized_properties = 0
owned_sources.each do |path, source|
  masked = mask_non_code(source)
  edits = []
  [/@property\b[^;]*;/m, /^[ \t]*Prop(?:_[A-Za-z_]\w*)?\s*\([^)]*\)\s*[^;]*;/m].each do |pattern|
    masked.to_enum(:scan, pattern).each do
      match = Regexp.last_match
      declaration = source[match.begin(0)...match.end(0)]
      next unless block_return?(declaration)

      name = declaration[/([A-Za-z_]\w*)\s*;\s*\z/m, 1]
      next unless name && explicit_nullable_block_getter_names.include?(name)
      next if declaration.match?(/\b(?:nullable|_Nullable)\b/)

      if declaration.start_with?("@property")
        closing = declaration.index(")")
        next unless closing

        edits << [match.begin(0) + closing, ", nullable"]
      else
        opening = declaration.index("(")
        next unless opening

        edits << [match.begin(0) + opening + 1, "nullable"]
      end
    end
  end
  next if edits.empty?

  updated = source.dup
  edits.reverse_each { |offset, value| updated.insert(offset, value) }
  File.binwrite(path, updated) if options[:apply]
  owned_sources[path] = updated
  puts [options[:apply] ? "updated-property" : "would-update-property", path, edits.length].join("\t")
  normalized_property_files += 1
  normalized_properties += edits.length
end


block_property_names = Set.new
nullable_block_property_names = Set.new
owned_sources.each_value do |source|
  masked = mask_non_code(source)
  [/@property\b[^;]*;/m, /^[ \t]*Prop(?:_[A-Za-z_]\w*)?\s*\([^)]*\)\s*[^;]*;/m].each do |pattern|
    masked.to_enum(:scan, pattern).each do
      match = Regexp.last_match
      declaration = source[match.begin(0)...match.end(0)]
      next unless block_return?(declaration)

      name = declaration[/([A-Za-z_]\w*)\s*;\s*\z/m, 1]
      next unless name

      block_property_names << name
      nullable_block_property_names << name if declaration.match?(/\b(?:nullable|_Nullable)\b/)
    end
  end
end

changed_files = 0
changed_methods = 0
converted_nullable = 0
restored_nullable_properties = 0
owned_sources.each do |path, source|
  masked = mask_non_code(source)
  edits = []
  masked.to_enum(:scan, /^[ \t]*[+-][ \t]*\(([^\r\n()]*)\)[ \t]*([A-Za-z_]\w*)/m).each do
    match = Regexp.last_match
    return_type = source[match.begin(1)...match.end(1)]
    next unless block_return?(return_type)
    selector = match[2]

    if nullable_block_property_names.include?(selector)
      if return_type.match?(/\b_Nonnull\b/)
        nonnull_offset = match.begin(1) + return_type.index("_Nonnull")
        edits << [nonnull_offset, "_Nullable", "replace-nonnull"]
        restored_nullable_properties += 1
      end
      next
    end
    next if block_property_names.include?(selector)
    next if return_type.match?(/\b_Nonnull\b/)

    if return_type.match?(/\b_Nullable\b/)
      nullable_offset = match.begin(1) + return_type.index("_Nullable")
      edits << [nullable_offset, "_Nonnull", "replace"]
      converted_nullable += 1
      next
    end

    edits << [match.end(1), " _Nonnull", "insert"]
  end
  next if edits.empty?

  updated = source.dup
  edits.reverse_each do |offset, value, action|
    if action == "replace"
      updated[offset, "_Nullable".bytesize] = value
    elsif action == "replace-nonnull"
      updated[offset, "_Nonnull".bytesize] = value
    else
      updated.insert(offset, value)
    end
  end
  File.binwrite(path, updated) if options[:apply]
  puts [options[:apply] ? "updated" : "would-update", path, edits.length].join("\t")
  changed_files += 1
  changed_methods += edits.length
end

warn "methods=#{changed_methods} files=#{changed_files} converted_nullable=#{converted_nullable} restored_nullable_properties=#{restored_nullable_properties} normalized_properties=#{normalized_properties} normalized_property_files=#{normalized_property_files} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
