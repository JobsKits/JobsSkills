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

OPENING_FOR = { 41 => 40, 93 => 91, 125 => 123 }.freeze
CLOSING_FOR = OPENING_FOR.invert.freeze

def matching_forward(masked, opening)
  stack = []
  (opening...masked.bytesize).each do |index|
    byte = masked.getbyte(index)
    stack << byte if CLOSING_FOR.key?(byte)
    next unless OPENING_FOR.key?(byte)
    return nil if stack.empty? || stack.pop != OPENING_FOR.fetch(byte)
    return index if stack.empty?
  end
  nil
end

def matching_backward(masked, closing)
  stack = []
  closing.downto(0) do |index|
    byte = masked.getbyte(index)
    stack << byte if OPENING_FOR.key?(byte)
    next unless CLOSING_FOR.key?(byte)
    return nil if stack.empty? || CLOSING_FOR.fetch(byte) != stack.pop
    return index if stack.empty?
  end
  nil
end

def receiver_start(masked, dot)
  index = dot - 1
  index -= 1 while index >= 0 && masked.getbyte(index)&.chr&.match?(/\s/)
  return nil if index.negative?

  if OPENING_FOR.key?(masked.getbyte(index))
    matching_backward(masked, index)
  else
    index -= 1 while index >= 0 && masked.getbyte(index)&.chr&.match?(/[A-Za-z0-9_\.]/)
    index + 1
  end
end

def restore_calls(source)
  masked = mask_non_code(source)
  block_getter_edits = []
  block_getter_pattern = /\[\s*(self|\(\(NSObject \*\)target\))\s+(jobsSelectorBlock|onImageLoaded)\s*:/
  masked.to_enum(:scan, block_getter_pattern).each do
    match = Regexp.last_match
    opening = match.begin(0)
    closing = matching_forward(masked, opening)
    next unless closing

    receiver = match[1]
    method = match[2]
    argument = source[match.end(0)...closing]
    block_getter_edits << [opening, closing + 1, "#{receiver}.#{method}(#{argument})"]
  end
  block_getter_edits.reverse_each do |start_offset, end_offset, replacement|
    source[start_offset...end_offset] = replacement
  end

  masked = mask_non_code(source)
  message_edits = []
  pattern = /\.\s*(addObject|objectAtIndex|removeObjectAtIndex|removeObjectsAtIndexes|imageNamed|imageWithData|drawInContext|dequeueReusableCellWithIdentifier|dequeueReusableHeaderFooterViewWithIdentifier|setFrame|setSelected|sizeThatFits|preferredContentSizeDidChangeForChildContentContainer|startInteractiveTransition|setTag|setEnabled|applyLayoutAttributes|fontWithSize|openURL|reloadData)\s*\(/
  masked.to_enum(:scan, pattern).each do
    match = Regexp.last_match
    method = match[1]
    dot = match.begin(0)
    opening = match.end(0) - 1
    closing = matching_forward(masked, opening)
    start = receiver_start(masked, dot)
    next unless start && closing

    receiver = source[start...dot].strip
    next if %w[imageNamed imageWithData].include?(method) && receiver != "UIImage"
    next if method == "openURL" && !%w[UIApplication.sharedApplication application].include?(receiver)
    next if method == "reloadData" && receiver != "super"

    argument = source[(opening + 1)...closing]
    message_edits << [start, closing + 1, "[#{receiver} #{method}:#{argument}]"]
  end
  message_edits.uniq.sort_by { |start_offset, end_offset, _| [start_offset, end_offset] }.reverse_each do |start_offset, end_offset, replacement|
    source[start_offset...end_offset] = replacement
  end
  [source, block_getter_edits.length + message_edits.length]
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: restore_oc_fixed_one_argument_calls.rb [--apply] PATH..."
  parser.on("--apply", "Restore fixed Foundation/UIKit message calls") { options[:apply] = true }
end.parse!

roots = ARGV.empty? ? ["."] : ARGV
changed = 0
call_count = 0
source_files(roots).each do |path|
  original = File.binread(path)
  next unless original.dup.force_encoding(Encoding::UTF_8).valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, original)

  source, count = restore_calls(original.dup)
  next if count.zero?

  File.binwrite(path, source) if options[:apply]
  changed += 1
  call_count += count
  puts [options[:apply] ? "updated" : "would-update", path, count].join("\t")
end

warn "files=#{changed} calls=#{call_count} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
