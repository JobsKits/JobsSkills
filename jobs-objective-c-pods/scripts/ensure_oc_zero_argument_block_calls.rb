#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
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
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{h,m,mm}"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end

def mask_non_code(source)
  masked = source.dup
  index = 0
  state = :code
  while index < source.bytesize
    current = source.getbyte(index)
    following = index + 1 < source.bytesize ? source.getbyte(index + 1) : nil
    case state
    when :code
      if current == 47 && following == 47
        masked.setbyte(index, 32)
        masked.setbyte(index + 1, 32)
        index += 2
        state = :line_comment
        next
      elsif current == 47 && following == 42
        masked.setbyte(index, 32)
        masked.setbyte(index + 1, 32)
        index += 2
        state = :block_comment
        next
      elsif current == 34
        masked.setbyte(index, 32)
        state = :string
      elsif current == 39
        masked.setbyte(index, 32)
        state = :character
      end
    when :line_comment
      if current == 10
        state = :code
      else
        masked.setbyte(index, 32)
      end
    when :block_comment
      if current == 42 && following == 47
        masked.setbyte(index, 32)
        masked.setbyte(index + 1, 32)
        index += 2
        state = :code
        next
      else
        masked.setbyte(index, 32) unless current == 10
      end
    when :string, :character
      terminal = state == :string ? 34 : 39
      if current == 92
        masked.setbyte(index, 32)
        index += 1
        masked.setbyte(index, 32) if index < source.bytesize && source.getbyte(index) != 10
      elsif current == terminal
        masked.setbyte(index, 32)
        state = :code
      else
        masked.setbyte(index, 32) unless current == 10
      end
    end
    index += 1
  end
  masked
end

def ensure_calls(source, selectors, rename_to = nil, remove_call = false)
  masked = mask_non_code(source)
  selector_pattern = Regexp.union(selectors.sort_by { |selector| -selector.length })
  edits = []
  if rename_to
    masked.to_enum(:scan, /\.\s*(#{selector_pattern})\b(?=\s*\()/).each do
      match = Regexp.last_match
      edits << [match.begin(1), match.end(1), rename_to]
    end
  elsif remove_call
    masked.to_enum(:scan, /\.\s*(#{selector_pattern})\b\s*\(\s*\)/).each do
      match = Regexp.last_match
      edits << [match.end(1), match.end(0), ""]
    end
  else
    masked.to_enum(:scan, /\.\s*(#{selector_pattern})\b(?!\s*\()/).each do
      match = Regexp.last_match
      edits << [match.end(1), match.end(1), "()"]
    end
    masked.to_enum(:scan, /\[\s*[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\s+(#{selector_pattern})\s*\](?!\s*\()/).each do
      match = Regexp.last_match
      edits << [match.end(0), match.end(0), "()"]
    end
  end
  edits.uniq.sort_by(&:first).reverse_each do |start_offset, end_offset, replacement|
    source[start_offset...end_offset] = replacement
  end
  [source, edits.length]
end

def ensure_same_file_self_bracket_calls(source, selectors)
  masked = mask_non_code(source)
  implemented = masked.scan(
    /^[ \t]*[+-][ \t]*\(([^)\n]*(?:Block|Blocks)[^)\n]*)\)[ \t]*([A-Za-z_]\w*)[ \t]*(?:API_[A-Z_]+\([^\n]*\)[ \t]*)?\{/m
  ).map { |_, selector| selector }.uniq & selectors
  # A getter whose matching setter is implemented in the same file is a Block
  # property accessor. Reading, assigning, returning or forwarding that Block is
  # not equivalent to invoking a functional Block API.
  implemented.reject! do |selector|
    setter = "set#{selector[0].upcase}#{selector[1..]}"
    masked.match?(/^[ \t]*[+-][ \t]*\([^\n)]*\)[ \t]*#{Regexp.escape(setter)}[ \t]*:/m)
  end
  return [source, 0] if implemented.empty?

  selector_pattern = Regexp.union(implemented.sort_by { |selector| -selector.length })
  edits = []
  masked.to_enum(:scan, /\bself\.(#{selector_pattern})\b(?!\s*\()/).each do
    match = Regexp.last_match
    line_start = masked.rindex("\n", match.begin(0))
    line_start = line_start ? line_start + 1 : 0
    line_end = masked.index("\n", match.end(0)) || masked.length
    prefix = masked[line_start...match.begin(0)]
    suffix = masked[match.end(0)...line_end]
    next unless suffix.match?(/\A\s*;/)
    next if prefix.include?("=") || prefix.match?(/\breturn\b/)

    edits << [match.end(1), match.end(1), "()"]
  end
  masked.to_enum(:scan, /\[\s*self\s+(#{selector_pattern})\s*\](?!\s*\()/).each do
    match = Regexp.last_match
    line_start = masked.rindex("\n", match.begin(0))
    line_start = line_start ? line_start + 1 : 0
    line_end = masked.index("\n", match.end(0)) || masked.length
    prefix = masked[line_start...match.begin(0)]
    suffix = masked[match.end(0)...line_end]
    next unless suffix.match?(/\A\s*;/)
    next if prefix.include?("=") || prefix.match?(/\breturn\b/)

    edits << [match.end(0), match.end(0), "()"]
  end
  edits.uniq.sort_by(&:first).reverse_each do |start_offset, end_offset, replacement|
    source[start_offset...end_offset] = replacement
  end
  [source, edits.length]
end

options = {
  apply: false,
  selectors: [],
  selectors_files: [],
  rename_to: nil,
  remove_call: false,
  same_file_self_only: false
}
OptionParser.new do |parser|
  parser.banner = "Usage: ensure_oc_zero_argument_block_calls.rb (--selector NAME | --selectors-file FILE) [--apply] PATH..."
  parser.on("--selector NAME", "Zero-argument Block selector; repeatable") { |value| options[:selectors] << value }
  parser.on("--selectors-file FILE", "Read zero-argument Block selectors from a newline-delimited file") do |value|
    options[:selectors_files] << value
  end
  parser.on("--rename-to NAME", "Rename an already invoked Block selector while preserving its arguments") { |value| options[:rename_to] = value }
  parser.on("--remove-call", "Remove an empty argument list from a fixed property or compatibility getter") { options[:remove_call] = true }
  parser.on("--same-file-self-only", "Only invoke self.selector / [self selector] when this file implements selector as a Block getter") do
    options[:same_file_self_only] = true
  end
  parser.on("--apply", "Add the missing empty argument list") { options[:apply] = true }
end.parse!

options[:selectors_files].each do |path|
  options[:selectors].concat(File.readlines(path, chomp: true).map(&:strip).reject(&:empty?))
end

abort "At least one --selector or --selectors-file entry is required" if options[:selectors].empty?
abort "--rename-to requires exactly one --selector" if options[:rename_to] && options[:selectors].length != 1
abort "--rename-to and --remove-call are mutually exclusive" if options[:rename_to] && options[:remove_call]
abort "--same-file-self-only cannot be combined with --rename-to or --remove-call" if
  options[:same_file_self_only] && (options[:rename_to] || options[:remove_call])
abort "At least one source root is required" if ARGV.empty?

changed = 0
call_count = 0
source_files(ARGV).each do |path|
  original = File.binread(path)
  next unless original.dup.force_encoding(Encoding::UTF_8).valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, original)

  source, count = if options[:same_file_self_only]
                    ensure_same_file_self_bracket_calls(original.dup, options[:selectors].uniq)
                  else
                    ensure_calls(original.dup, options[:selectors].uniq, options[:rename_to], options[:remove_call])
                  end
  next if count.zero?

  File.binwrite(path, source) if options[:apply]
  changed += 1
  call_count += count
  puts [options[:apply] ? "updated" : "would-update", path, count].join("\t")
end

warn "files=#{changed} calls=#{call_count} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
