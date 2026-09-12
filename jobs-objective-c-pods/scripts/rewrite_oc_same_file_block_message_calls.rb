#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"
require "set"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

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

MethodInfo = Struct.new(
  :return_type, :selector, :parameter_count, :body_open, :body_close,
  keyword_init: true
)

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

def parse_methods(source, masked)
  methods = []
  offset = 0
  while (match = masked.match(/^[ \t]*[+-][ \t]*\(/m, offset))
    opening = masked.index("(", match.begin(0))
    closing = matching_delimiter(masked, opening, 40, 41)
    break unless closing
    terminator = signature_terminator(masked, closing + 1)
    break unless terminator

    signature = source[(closing + 1)...terminator].strip.gsub(/\s+/, " ")
    labels = signature.scan(/\b([A-Za-z_]\w*)\s*:/).flatten
    selector = labels.empty? ? signature[/\A([A-Za-z_]\w*)/, 1] : "#{labels.join(':')}:"
    methods << MethodInfo.new(
      return_type: source[(opening + 1)...closing].strip,
      selector: selector,
      parameter_count: labels.length,
      body_open: masked.getbyte(terminator) == 123 ? terminator : nil,
      body_close: nil
    ) if selector
    body_close = masked.getbyte(terminator) == 123 ? matching_delimiter(masked, terminator, 123, 125) : nil
    methods.last.body_close = body_close if selector && methods.last&.body_open == terminator
    offset = body_close ? body_close + 1 : terminator + 1
  end
  methods
end

def block_return?(return_type)
  return_type.include?("(^") ||
    return_type.match?(/\b(?:Jobs|jobs)[A-Za-z_]\w*Blocks?\b/) ||
    return_type.match?(/\b\w+_block_t\b/)
end

options = { apply: false, selectors: Set.new }
OptionParser.new do |parser|
  parser.banner = "Usage: rewrite_oc_same_file_block_message_calls.rb [--apply] PATH..."
  parser.on("--selector NAME", "Also rewrite this reviewed Block selector for any simple receiver; repeatable") do |value|
    options[:selectors] << value
  end
  parser.on("--apply", "Rewrite unambiguous [self selector:arg] calls to self.selector(arg)") { options[:apply] = true }
end.parse!
abort "At least one path is required" if ARGV.empty?

changed_files = 0
changed_calls = 0
source_files(ARGV).each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  masked = mask_non_code(source)
  methods = parse_methods(source, masked)
  block_bases = methods.select { |method| method.parameter_count.zero? && block_return?(method.return_type) }
                       .map(&:selector).to_set
  traditional_bases = methods.select { |method| method.parameter_count == 1 && !block_return?(method.return_type) }
                             .map { |method| method.selector.delete_suffix(":") }.to_set
  candidates = (block_bases - traditional_bases) | options[:selectors]
  next if candidates.empty?

  stack = []
  edits = []
  masked.bytes.each_with_index do |byte, index|
    if byte == 91
      stack << index
    elsif byte == 93 && stack.any?
      opening = stack.pop
      inner_masked = masked[(opening + 1)...index]
      depth = 0
      colons = []
      pending_ternaries = 0
      multi_argument = false
      inner_masked.bytes.each_with_index do |inner_byte, inner_index|
        case inner_byte
        when 40, 91, 123 then depth += 1
        when 41, 93, 125 then depth -= 1
        when 63
          pending_ternaries += 1 if depth.zero? && colons.any?
        when 58
          next unless depth.zero?

          if colons.empty?
            colons << inner_index
          elsif pending_ternaries.positive?
            pending_ternaries -= 1
          else
            multi_argument = true
          end
        end
      end
      next unless colons.length == 1 && !multi_argument

      colon = colons.first
      prefix = inner_masked[0...colon]
      match = prefix.match(/\A\s*((?:self|[A-Za-z_]\w*)(?:\.[A-Za-z_]\w*)*)\s+([A-Za-z_]\w*)\s*\z/m)
      next unless match && candidates.include?(match[2])
      next if match[1] == "super"
      next unless match[1] == "self" || options[:selectors].include?(match[2])

      enclosing_method = methods.find do |method|
        method.body_open && method.body_close && method.body_open < opening && opening < method.body_close
      end
      if match[1] == "self" &&
         FIXED_ONE_ARGUMENT_SELECTORS.include?(match[2]) &&
         enclosing_method&.selector == match[2] &&
         block_return?(enclosing_method.return_type)
        next
      end

      inner_source = source[(opening + 1)...index]
      argument = inner_source[(colon + 1)..].to_s.strip
      edits << [opening, index + 1, "#{match[1]}.#{match[2]}(#{argument})"]
    end
  end
  next if edits.empty?

  kept = []
  edits.sort_by { |entry| [entry[0], entry[1]] }.each do |entry|
    next if kept.any? { |candidate| candidate[0] < entry[1] && entry[0] < candidate[1] }

    kept << entry
  end
  updated = source.dup
  kept.reverse_each { |start_offset, end_offset, replacement| updated[start_offset...end_offset] = replacement }
  File.binwrite(path, updated) if options[:apply]
  puts [options[:apply] ? "updated" : "would-update", path, kept.length].join("\t")
  changed_files += 1
  changed_calls += kept.length
end

warn "calls=#{changed_calls} files=#{changed_files} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
