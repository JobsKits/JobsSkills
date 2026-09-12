#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"
require "set"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze
COMPATIBILITY_WRAPPER_SELECTORS = Set.new(%w[
  appDisplayName
  bundlePath
  image
  imageURLPlus
  jobsUrl
  titleForNormalState
]).freeze

# UIKit 固定属性可能与 Jobs 自定义方法同名；无类型语法改写不得给这些系统属性追加 Block 调用括号。
PROTECTED_ZERO_CALL_SELECTORS = Set.new(%w[
  platformIDStr
  simulatorModel
  canBecomeFirstResponder
  childViewControllerForStatusBarStyle
  collectionViewContentSize
  layoutIfNeeded
  load
  prefersStatusBarHidden
  placeSubviews
  prepareLayout
  supportsSecureCoding
  webView
  normalBgImageURL
  normalBgImageURLString
  normalImageURL
  normalImageURLString
  modelContainerPropertyGenericClass
  modelCustomPropertyMapper
  activityType
  horizontalLayout
  verticalLayout
  timeFormatter
  getCurrentViewController
  currentDate
  currentDevice
  CellHeight
  CellWidth
  counter
  headerHeight
  isSelected
  isSimulator
  intrinsicContentSize
  calendar
  customHTTPHeader
  edgeInsets
  indicatorSize
  parameters
  pageTitle
  presentedView
  rootViewController
  shouldAutorotate
  securityModelBtn
  sound
  subTitleFont
  textLab
  topViewController
  width
  height
  webView
]).freeze

# 有参方法名也可能与 UIKit 固定 API 同名；这些方法只改定义，不做无类型的全局调用点改写。
PROTECTED_ONE_CALL_SELECTORS = Set.new(%w[
  addObject:
  objectAtIndex:
  removeObjectAtIndex:
  imageNamed:
  imageWithData:
  drawInContext:
  updateInteractiveMovementTargetPosition:
]).freeze

MethodInfo = Struct.new(
  :path, :kind, :start_offset, :return_open, :return_close, :return_type,
  :selector, :base_selector, :parameter_type, :parameter_name, :terminator,
  :body_close, :block_type,
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

def parse_parameter(signature)
  colon = signature.index(":")
  return [nil, nil] unless colon

  opening = signature.index("(", colon)
  return [nil, nil] unless opening

  depth = 0
  closing = nil
  signature.bytes.each_with_index do |byte, index|
    next if index < opening

    depth += 1 if byte == 40
    if byte == 41
      depth -= 1
      if depth.zero?
        closing = index
        break
      end
    end
  end
  return [nil, nil] unless closing

  type = signature[(opening + 1)...closing].strip
  name = signature[(closing + 1)..].to_s.strip[/\A([A-Za-z_]\w*)/, 1]
  [type, name]
end

def parse_methods(path, source, masked, plans)
  methods = []
  offset = 0
  pattern = /^[ \t]*([+-])[ \t]*\(/m
  while (match = masked.match(pattern, offset))
    opening = masked.index("(", match.begin(0))
    closing = matching_delimiter(masked, opening, 40, 41)
    break unless closing

    terminator = signature_terminator(masked, closing + 1)
    break unless terminator

    signature = source[(closing + 1)...terminator].strip.gsub(/\s+/, " ")
    selector = if signature.include?(":")
                 signature.scan(/([A-Za-z_]\w*)\s*:/).flatten.join(":") + ":"
               else
                 # API_AVAILABLE / NS_SWIFT_NAME 等声明属性可能跟在零参数选择器后面。
                 signature[/\A([A-Za-z_]\w*)\b/, 1]
               end
    key = [match[1], selector]
    block_type = plans[key]
    if block_type
      parameter_type, parameter_name = parse_parameter(signature)
      if selector&.include?(":") && (!parameter_type || !parameter_name)
        abort "Unable to parse the single parameter in #{path}: #{signature}"
      end
      body_close = masked.getbyte(terminator) == 123 ? matching_delimiter(masked, terminator, 123, 125) : nil
      methods << MethodInfo.new(
        path: path,
        kind: match[1],
        start_offset: match.begin(0),
        return_open: opening,
        return_close: closing,
        return_type: source[(opening + 1)...closing].strip,
        selector: selector,
        base_selector: selector.delete_suffix(":"),
        parameter_type: parameter_type,
        parameter_name: parameter_name,
        terminator: terminator,
        body_close: body_close,
        block_type: block_type
      )
    end
    offset = (masked.getbyte(terminator) == 123 && (ending = matching_delimiter(masked, terminator, 123, 125))) ? ending + 1 : terminator + 1
  end
  methods
end

def indented_body(body)
  value = body.sub(/\A\r?\n/, "").sub(/\r?\n[ \t]*\z/, "")
  value.lines.map { |line| line.strip.empty? ? line : "    #{line}" }.join
end

def object_return?(type)
  type.include?("*") || type.match?(/\b(?:id|instancetype|Class)\b/)
end

def nil_return(type)
  object_return?(type) ? "return nil;" : "return (#{type}){0};"
end

def block_literal_return(method)
  return "" if method.return_type.gsub(/\s+/, "") == "void"
  return "__kindof #{method.path_context} *" if method.return_type.include?("instancetype") && method.respond_to?(:path_context)

  method.return_type
end

def add_edit(edits, start_offset, end_offset, replacement, label)
  edits << [start_offset, end_offset, replacement, label]
end

def inside_ranges?(offset, ranges)
  ranges.any? { |start_offset, end_offset| start_offset <= offset && offset < end_offset }
end

def simple_receiver?(receiver)
  receiver.match?(/\A(?:self|super|[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\z/)
end

def rewrite_zero_calls(fragment, selectors)
  return fragment if selectors.empty?

  masked = mask_non_code(fragment)
  edits = []
  pattern = /\.\s*(#{Regexp.union(selectors.sort_by { |name| -name.length })})\b(?!\s*(?:\(|\)\s*\(|\+\+|--|(?:<<|>>|[+\-*\/%|&^])?=))/
  masked.to_enum(:scan, pattern).each do
    match = Regexp.last_match
    ending = match.begin(1) + match[1].bytesize
    add_edit(edits, ending, ending, "()", "zero-dot-call")
  end
  edits.uniq.sort_by { |entry| [entry[0], entry[1]] }.reverse_each do |start_offset, end_offset, replacement, _label|
    fragment[start_offset...end_offset] = replacement
  end
  fragment
end

def add_zero_call_edits(masked, selectors, edits, skipped_ranges = [])
  return if selectors.empty?

  pattern = /\.\s*(#{Regexp.union(selectors.sort_by { |name| -name.length })})\b(?!\s*(?:\(|\)\s*\(|\+\+|--|(?:<<|>>|[+\-*\/%|&^])?=))/
  masked.to_enum(:scan, pattern).each do
    match = Regexp.last_match
    ending = match.begin(1) + match[1].bytesize
    next if inside_ranges?(ending, skipped_ranges)

    add_edit(edits, ending, ending, "()", "zero-dot-call #{match[1]}")
  end
end

def rewrite_zero_message_calls(source, masked, selectors, edits, skipped_ranges = [], selector_map = {})
  return if selectors.empty?

  stack = []
  masked.bytes.each_with_index do |byte, index|
    if byte == 91
      stack << index
    elsif byte == 93 && stack.any?
      opening = stack.pop
      next if inside_ranges?(opening, skipped_ranges)

      inner_masked = masked[(opening + 1)...index]
      next if inner_masked.include?(":")

      match = inner_masked.match(/\A\s*(.+)\s+(#{Regexp.union(selectors.sort_by { |name| -name.length })})\s*\z/m)
      next unless match

      inner_source = source[(opening + 1)...index]
      source_match = inner_source.match(/\A\s*(.+)\s+#{Regexp.escape(match[2])}\s*\z/m)
      next unless source_match

      receiver = rewrite_call_fragment(source_match[1].strip, selector_map, selectors)
      receiver_expr = simple_receiver?(receiver) ? receiver : "(#{receiver})"
      replacement = "#{receiver_expr}.#{match[2]}()"
      add_edit(edits, opening, index + 1, replacement, "zero-message-call #{match[2]}")
    end
  end
end

def rewrite_one_message_calls(source, masked, selector_map, edits, skipped_ranges = [], zero_selectors = [])
  stack = []
  masked.bytes.each_with_index do |byte, index|
    if byte == 91
      stack << index
    elsif byte == 93 && stack.any?
      opening = stack.pop
      next if inside_ranges?(opening, skipped_ranges)

      inner_masked = masked[(opening + 1)...index]
      depth = 0
      top_level_colons = []
      inner_masked.bytes.each_with_index do |inner_byte, inner_index|
        case inner_byte
        when 40, 91, 123 then depth += 1
        when 41, 93, 125 then depth -= 1
        when 58
          top_level_colons << inner_index if depth.zero?
        end
      end
      # 只有一个顶层冒号才是一参方法；多参消息不能只改冒号前半段。
      next unless top_level_colons.length == 1

      colon = top_level_colons.first

      prefix_masked = inner_masked[0...colon]
      match = prefix_masked.match(/\A\s*(.+)\s+([A-Za-z_]\w*)\s*\z/m)
      next unless match

      selector = "#{match[2]}:"
      base = selector_map[selector]
      next unless base

      inner_source = source[(opening + 1)...index]
      prefix_source = inner_source[0...colon]
      argument = rewrite_call_fragment(inner_source[(colon + 1)..].to_s.strip, selector_map, zero_selectors)
      source_match = prefix_source.match(/\A\s*(.+)\s+#{Regexp.escape(match[2])}\s*\z/m)
      next unless source_match

      receiver = rewrite_call_fragment(source_match[1].strip, selector_map, zero_selectors)
      receiver_expr = simple_receiver?(receiver) ? receiver : "(#{receiver})"
      replacement = "#{receiver_expr}.#{base}(#{argument})"
      add_edit(edits, opening, index + 1, replacement, "one-message-call #{selector}")
    end
  end
end

def rewrite_call_fragment(fragment, selector_map, zero_selectors)
  edits = []
  masked = mask_non_code(fragment)
  rewrite_one_message_calls(fragment, masked, selector_map, edits, [], zero_selectors)
  rewrite_zero_message_calls(fragment, masked, zero_selectors, edits, [], selector_map)
  kept = []
  edits.uniq.sort_by { |entry| [entry[0], -entry[1]] }.each do |entry|
    overlap = kept.find { |candidate| candidate[0] < entry[1] && entry[0] < candidate[1] }
    next if overlap && overlap[0] <= entry[0] && overlap[1] >= entry[1]
    kept << entry unless overlap
  end
  kept.sort_by { |entry| [entry[0], entry[1]] }.reverse_each do |start_offset, end_offset, replacement, _label|
    fragment[start_offset...end_offset] = replacement
  end
  rewrite_zero_calls(fragment, zero_selectors)
end

def rewrite_one_calls_in_fragment(fragment, selector_map, zero_selectors = [])
  edits = []
  rewrite_one_message_calls(fragment, mask_non_code(fragment), selector_map, edits, [], zero_selectors)
  edits.uniq.sort_by { |entry| [entry[0], entry[1]] }.reverse_each do |start_offset, end_offset, replacement, _label|
    fragment[start_offset...end_offset] = replacement
  end
  fragment
end

def rewrite_zero_messages_in_fragment(fragment, selectors, selector_map = {})
  edits = []
  rewrite_zero_message_calls(fragment, mask_non_code(fragment), selectors, edits, [], selector_map)
  edits.uniq.sort_by { |entry| [entry[0], entry[1]] }.reverse_each do |start_offset, end_offset, replacement, _label|
    fragment[start_offset...end_offset] = replacement
  end
  fragment
end

def block_body(method, source, zero_selectors, one_selector_map)
  original = source[(method.terminator + 1)...method.body_close]
  original = rewrite_zero_messages_in_fragment(original, zero_selectors, one_selector_map)
  original = rewrite_zero_calls(original, zero_selectors)
  original = rewrite_one_calls_in_fragment(original, one_selector_map, zero_selectors)
  body = indented_body(original)
  is_void = method.return_type.gsub(/\s+/, "") == "void"
  literal_parameter_type = method.parameter_type&.gsub(/\b(?:nullable|nonnull)\b/, "")&.gsub(/\s+/, " ")&.strip
  parameter = literal_parameter_type ? "(#{literal_parameter_type} #{method.parameter_name})" : ""
  explicit_return = is_void ? "" : method.return_type.gsub(/\b(?:nullable|nonnull)\b/, "")
                                                .gsub(/\binstancetype\b/, "id")
                                                .gsub(/\s+/, " ").strip
  literal = "^#{explicit_return}#{parameter}"
  prefix = if method.kind == "-"
             "\n    @jobs_weakify(self)\n" \
               "    return #{literal}{\n" \
               "        @jobs_strongify(self)\n" \
               "        if (!self) #{is_void ? 'return;' : nil_return(method.return_type)}\n"
           else
             "\n    return #{literal}{\n"
           end
  suffix = body.empty? ? "    };\n" : "\n    };\n"
  "{#{prefix}#{body}#{suffix}}"
end

options = { apply: false, reports: [], method_roots: [], call_roots: [], rewrite_zero_calls: false }
OptionParser.new do |parser|
  parser.banner = "Usage: migrate_oc_functional_block_plan.rb [options]"
  parser.on("--coverage-report PATH", "Coverage TSV; repeatable") { |value| options[:reports] << value }
  parser.on("--method-root PATH", "Method root; repeatable") { |value| options[:method_roots] << value }
  parser.on("--call-root PATH", "Call-site root; repeatable") { |value| options[:call_roots] << value }
  parser.on("--rewrite-zero-calls", "Rewrite zero-argument dot calls (more collision-prone)") { options[:rewrite_zero_calls] = true }
  parser.on("--apply", "Write edits") { options[:apply] = true }
end.parse!

abort "At least one --coverage-report is required" if options[:reports].empty?
abort "At least one --method-root is required" if options[:method_roots].empty?
options[:call_roots] = options[:method_roots] if options[:call_roots].empty?

plans_by_path = Hash.new { |hash, key| hash[key] = {} }
options[:reports].each do |report|
  File.foreach(report) do |line|
    fields = line.chomp.split("\t", -1)
    next unless fields[0] == "matched"

    path = File.expand_path(fields[1])
    kind = fields[4]
    selector = fields[5]
    next if COMPATIBILITY_WRAPPER_SELECTORS.include?(selector)

    block_type = fields[10]
    plans_by_path[path][[kind, selector]] = block_type
  end
end

all_paths = source_files(options[:method_roots]) | source_files(options[:call_roots])
sources = {}
all_paths.each do |path|
  source = File.binread(path)
  next unless source.dup.force_encoding(Encoding::UTF_8).valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  sources[path] = [source, mask_non_code(source)]
end

methods = []
plans_by_path.each do |path, plans|
  next unless sources[path]
  methods.concat(parse_methods(path, sources[path][0], sources[path][1], plans))
end

zero_selectors = methods.select { |method| !method.selector.include?(":") }
                        .map(&:selector)
                        .reject { |selector| PROTECTED_ZERO_CALL_SELECTORS.include?(selector) }
                        .uniq
one_selector_map = methods.select { |method| method.selector.end_with?(":") }
                          .reject { |method| PROTECTED_ONE_CALL_SELECTORS.include?(method.selector) }
                          .to_h { |method| [method.selector, method.base_selector] }
edits_by_path = Hash.new { |hash, key| hash[key] = [] }
replaced_ranges = Hash.new { |hash, key| hash[key] = [] }

methods.each do |method|
  source = sources.fetch(method.path).first
  if method.selector.include?(":")
    if method.body_close
      block_method = "#{method.kind}(#{method.block_type} _Nonnull)#{method.base_selector}" \
                     "#{block_body(method, source, zero_selectors, one_selector_map)}"
      replacement = block_method
      add_edit(edits_by_path[method.path], method.start_offset, method.body_close + 1, replacement, "one-method #{method.selector}")
      replaced_ranges[method.path] << [method.start_offset, method.body_close + 1]
    else
      declaration = "#{method.kind}(#{method.block_type} _Nonnull)#{method.base_selector};"
      add_edit(edits_by_path[method.path], method.start_offset, method.terminator + 1, declaration, "one-declaration #{method.selector}")
    end
  else
    add_edit(edits_by_path[method.path], method.return_open + 1, method.return_close, "#{method.block_type} _Nonnull", "zero-return #{method.selector}")
    next unless method.body_close

    replacement = block_body(method, source, zero_selectors, one_selector_map)
    add_edit(edits_by_path[method.path], method.terminator, method.body_close + 1, replacement, "zero-body #{method.selector}")
    replaced_ranges[method.path] << [method.terminator, method.body_close + 1]
  end
end

sources.each do |path, (source, masked)|
  rewrite_one_message_calls(source, masked, one_selector_map, edits_by_path[path], replaced_ranges[path], zero_selectors)
  next unless options[:rewrite_zero_calls]

  rewrite_zero_message_calls(source, masked, zero_selectors, edits_by_path[path], replaced_ranges[path], one_selector_map)
  add_zero_call_edits(masked, zero_selectors, edits_by_path[path], replaced_ranges[path])
end

changed = 0
edits_by_path.each do |path, edits|
  next if edits.empty?

  pruned = []
  edits.uniq.sort_by { |entry| [entry[0], -entry[1]] }.each do |entry|
    overlap = pruned.find { |kept| kept[0] < entry[1] && entry[0] < kept[1] }
    if overlap
      if (overlap[3].start_with?("one-message-call") || overlap[3].start_with?("zero-message-call")) &&
         (entry[3].include?("-call") || entry[3].start_with?("zero-dot-call")) &&
         overlap[0] <= entry[0] && overlap[1] >= entry[1]
        next
      end
      abort "Overlapping edits in #{path}: #{overlap[3]} / #{entry[3]}"
    end
    pruned << entry
  end
  ordered = pruned.sort_by { |entry| [entry[0], entry[1]] }
  ordered.each_cons(2) do |left, right|
    abort "Overlapping edits in #{path}: #{left[3]} / #{right[3]}" if left[1] > right[0]
  end
  source = sources.fetch(path).first.dup
  ordered.reverse_each { |start_offset, end_offset, replacement, _label| source[start_offset...end_offset] = replacement }
  File.binwrite(path, source) if options[:apply]
  changed += 1
  puts [options[:apply] ? "updated" : "would-update", path, ordered.length].join("\t")
end

warn "methods=#{methods.length} zero_selectors=#{zero_selectors.length} one_selectors=#{one_selector_map.length} files=#{changed} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
