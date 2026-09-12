#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"
require "set"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

MethodInfo = Struct.new(
  :selector, :return_type, :body_open, :body_close,
  keyword_init: true
)

FIXED_ONE_ARGUMENT_SELECTORS = Set.new(%w[
  addChildViewController addInteraction addObject addSublayer addSubview
  applyLayoutAttributes characterAtIndex containsObject containsString
  dequeueReusableCellWithIdentifier dequeueReusableHeaderFooterViewWithIdentifier
  drawInContext fontWithSize hasPrefix hasSuffix imageNamed imageWithData
  initWithData isEqual isEqualToString isKindOfClass isMemberOfClass loadRequest
  objectAtIndex objectForInfoDictionaryKey objectForKey openURL rangeAtIndex
  rangeOfString rectForFooterInSection rectForHeaderInSection reloadData
  removeInteraction removeObjectAtIndex removeObjectsAtIndexes setEnabled setFrame
  setSelected setTag sizeThatFits startInteractiveTransition substringFromIndex
  substringToIndex substringWithRange timeIntervalSinceDate valueForKey viewWithTag
]).freeze

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
  masked = source.b.dup
  index = 0
  state = :code
  while index < source.bytesize
    current = source.getbyte(index)
    following = index + 1 < source.bytesize ? source.getbyte(index + 1) : nil
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
        if index < source.bytesize
          masked.setbyte(index, 32) unless source.getbyte(index) == 10; index += 1
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

def matching_delimiter(source, opening, open_byte, close_byte)
  depth = 0
  cursor = opening
  while cursor < source.bytesize
    byte = source.getbyte(cursor)
    depth += 1 if byte == open_byte
    if byte == close_byte
      depth -= 1
      return cursor if depth.zero?
    end
    cursor += 1
  end
  nil
end

def signature_terminator(source, offset)
  parentheses = 0
  brackets = 0
  cursor = offset
  while cursor < source.bytesize
    case source.getbyte(cursor)
    when 40 then parentheses += 1
    when 41 then parentheses -= 1
    when 91 then brackets += 1
    when 93 then brackets -= 1
    when 59, 123
      return cursor if parentheses.zero? && brackets.zero?
    end
    cursor += 1
  end
  nil
end

def method_selector(signature)
  labels = signature.scan(/\b([A-Za-z_]\w*)\s*:/).flatten
  return "#{labels.join(':')}:" unless labels.empty?

  signature[/\A([A-Za-z_]\w*)\b/, 1]
end

def methods(source, masked)
  result = []
  offset = 0
  while (match = masked.match(/^[ \t]*[+-][ \t]*\(/m, offset))
    opening = masked.index("(", match.begin(0))
    closing = matching_delimiter(masked, opening, 40, 41)
    break unless closing

    terminator = signature_terminator(masked, closing + 1)
    break unless terminator

    if masked.getbyte(terminator) == 123
      body_close = matching_delimiter(masked, terminator, 123, 125)
      break unless body_close

      signature = source[(closing + 1)...terminator].strip.gsub(/\s+/, " ")
      result << MethodInfo.new(
        selector: method_selector(signature),
        return_type: source[(opening + 1)...closing].strip,
        body_open: terminator,
        body_close: body_close
      )
      offset = body_close + 1
    else
      offset = terminator + 1
    end
  end
  result
end

def block_type?(type)
  type.match?(/\b(?:Jobs|jobs)[A-Za-z_]\w*Blocks?\b/) || type.match?(/\b\w+_block_t\b/)
end

def top_level_comma?(masked_argument)
  parentheses = 0
  brackets = 0
  braces = 0
  masked_argument.each_byte do |byte|
    case byte
    when 40 then parentheses += 1
    when 41 then parentheses -= 1
    when 91 then brackets += 1
    when 93 then brackets -= 1
    when 123 then braces += 1
    when 125 then braces -= 1
    when 44
      return true if parentheses.zero? && brackets.zero? && braces.zero?
    end
  end
  false
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: restore_oc_recursive_block_kernel_dispatch.rb [--apply] PATH..."
  parser.on("--apply", "Restore same-name one-argument fixed selector calls inside Block kernels") do
    options[:apply] = true
  end
end.parse!

abort "At least one path is required" if ARGV.empty?

changed_files = 0
changed_calls = 0
unresolved_calls = 0
source_files(ARGV).each do |path|
  original = File.binread(path)
  next unless original.dup.force_encoding(Encoding::UTF_8).valid_encoding?
  next unless JobsOCOwnership.jobs_owned_file?(path, original)

  source = original.dup
  masked = mask_non_code(source)
  edits = []
  methods(source, masked).each do |method|
    next unless method.selector && !method.selector.include?(":")
    next unless block_type?(method.return_type)
    next unless FIXED_ONE_ARGUMENT_SELECTORS.include?(method.selector)

    body_start = method.body_open + 1
    body_masked = masked[body_start...method.body_close]
    receivers = ["self"]
    body_masked.scan(/\b(?:__\w+\s+)*(?:[A-Za-z_]\w*(?:\s*<[^;=]+>)?\s*\*+\s*)([A-Za-z_]\w*)\s*=\s*self\s*;/) do |capture|
      receivers << capture.first
    end
    receiver_pattern = receivers.uniq.map { |receiver| Regexp.escape(receiver) }.join("|")
    pattern = /\b(#{receiver_pattern})\s*\.\s*#{Regexp.escape(method.selector)}\s*\(/
    body_masked.to_enum(:scan, pattern).each do
      match = Regexp.last_match
      receiver = match[1]
      call_start = body_start + match.begin(0)
      opening = body_start + match.end(0) - 1
      closing = matching_delimiter(masked, opening, 40, 41)
      next unless closing && closing < method.body_close

      argument = source[(opening + 1)...closing]
      masked_argument = masked[(opening + 1)...closing]
      if argument.strip.empty? || top_level_comma?(masked_argument)
        unresolved_calls += 1
        line = source.byteslice(0, call_start).count("\n") + 1
        puts ["manual-review", path, line, method.selector].join("\t")
        next
      end

      replacement = "[#{receiver} #{method.selector}:#{argument}]"
      edits << [call_start, closing + 1, replacement]
      unless options[:apply]
        line = source.byteslice(0, call_start).count("\n") + 1
        puts ["candidate", path, line, method.selector].join("\t")
      end
    end
  end

  edits.sort_by! { |start_offset, end_offset, _| [start_offset, end_offset] }
  overlapping = edits.each_cons(2).any? { |left, right| left[1] > right[0] }
  if overlapping
    unresolved_calls += edits.length
    puts ["manual-review-overlap", path, edits.length].join("\t")
    next
  end

  next if edits.empty?

  edits.reverse_each do |start_offset, end_offset, replacement|
    source[start_offset...end_offset] = replacement
  end
  File.binwrite(path, source) if options[:apply]
  changed_files += 1
  changed_calls += edits.length
  puts [options[:apply] ? "updated" : "would-update", path, edits.length].join("\t")
end

warn "files=#{changed_files} calls=#{changed_calls} unresolved=#{unresolved_calls} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
exit(unresolved_calls.positive? ? 2 : 0)
