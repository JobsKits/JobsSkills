#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "pathname"

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
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{m,mm}"))
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

def mask_preprocessor(source)
  continuation = false
  source.lines.map do |line|
    directive = continuation || line.lstrip.start_with?("#")
    continuation = directive && line.rstrip.end_with?("\\")
    directive ? line.gsub(/[^\r\n]/, " ") : line
  end.join
end

def line_number(source, offset)
  source.byteslice(0...offset).count("\n") + 1
end

abort "At least one path is required" if ARGV.empty?

files = source_files(ARGV)
definitions = []
files.each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  masked = mask_preprocessor(mask_non_code(source))
  offset = 0
  while (implementation = masked.match(/@implementation\s+([A-Za-z_]\w*)(?:\s*\([^)]*\))?/, offset))
    owner = implementation[1]
    closing = masked.index(/@end\b/, implementation.end(0))
    break unless closing

    region = masked.byteslice(implementation.end(0)...closing)
    region.to_enum(:scan, /^[ \t]*([+-])[ \t]*\(([^\r\n()]*)\)[ \t]*([A-Za-z_]\w*)\b/m).each do
      method = Regexp.last_match
      type_start = implementation.end(0) + method.begin(2)
      type_end = implementation.end(0) + method.end(2)
      next unless block_return?(source.byteslice(type_start...type_end))

      absolute = implementation.end(0) + method.begin(0)
      definitions << [owner, method[1], method[3], path, line_number(source, absolute)]
    end
    offset = closing + 4
  end
end

duplicates = definitions.group_by { |owner, kind, selector, _path, _line| [owner, kind, selector] }
                        .select { |_key, values| values.length > 1 }

duplicates.sort.each do |(owner, kind, selector), values|
  puts "duplicate\t#{owner}\t#{kind}\t#{selector}\t#{values.length}"
  values.sort_by { |value| [value[3], value[4]] }.each do |_entry_owner, _entry_kind, _entry_selector, path, line|
    puts "definition\t#{path}\t#{line}"
  end
end

warn "duplicate_getters=#{duplicates.length} definitions=#{definitions.length} scanned_files=#{files.length}"
exit(duplicates.empty? ? 0 : 2)
