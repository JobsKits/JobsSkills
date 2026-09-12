#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"
require "set"

EXCLUDED_COMPONENTS = %w[
  .git
  Pods
  ManualByOCPods@Pods
  PodsManual
  build
  DerivedData
].freeze

MethodInfo = Struct.new(
  :path,
  :kind,
  :return_open,
  :return_close,
  :return_type,
  :selector,
  :terminator,
  :body_close,
  keyword_init: true
)

def excluded?(path)
  path.each_filename.any? { |component| EXCLUDED_COMPONENTS.include?(component) }
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
        masked.setbyte(index, 32)
        masked.setbyte(index + 1, 32)
        index += 2
        state = :line_comment
      elsif current == "/" && following == "*"
        masked.setbyte(index, 32)
        masked.setbyte(index + 1, 32)
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
        masked.setbyte(index, 32)
        masked.setbyte(index + 1, 32)
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

def matching_delimiter(source, opening, opening_byte, closing_byte)
  depth = 0
  cursor = opening
  while cursor < source.length
    byte = source.getbyte(cursor)
    depth += 1 if byte == opening_byte
    if byte == closing_byte
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
  while cursor < source.length
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

def normalized_type(type)
  type.gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__kindof)\b/, "")
      .gsub(/\s+/, "")
end

def parse_target_methods(path, source, masked, requested_return, allowed_selectors = nil)
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
    selector = signature[/\A([A-Za-z_]\w*)\z/, 1]
    return_type = source[(opening + 1)...closing].strip
    if selector &&
       (!allowed_selectors || allowed_selectors.include?(selector)) &&
       normalized_type(return_type) == normalized_type(requested_return)
      body_close = terminator == masked.index("{", terminator) ?
        matching_delimiter(masked, terminator, 123, 125) : nil
      methods << MethodInfo.new(
        path: path,
        kind: match[1],
        return_open: opening,
        return_close: closing,
        return_type: return_type,
        selector: selector,
        terminator: terminator,
        body_close: body_close
      )
    end
    offset = terminator + 1
  end
  methods
end

def indented_body(body)
  body = body.sub(/\A\r?\n/, "").sub(/\r?\n[ \t]*\z/, "")
  body.lines.map { |line| line.strip.empty? ? line : "    #{line}" }.join
end

def rewrite_calls_in_fragment(fragment, selectors)
  return fragment if selectors.empty?

  masked = mask_non_code(fragment)
  edits = []
  add_dot_call_edits(fragment, masked, selectors, edits)
  add_simple_message_call_edits(fragment, masked, selectors, edits)
  edits.uniq.sort_by { |start_offset, end_offset, _replacement, _label| [start_offset, end_offset] }
       .reverse_each do |start_offset, end_offset, replacement, _label|
    fragment[start_offset...end_offset] = replacement
  end
  fragment
end

def block_wrapped_body(method, source, block_return, call_selectors)
  original = source[(method.terminator + 1)...method.body_close]
  original = rewrite_calls_in_fragment(original, call_selectors)
  body = indented_body(original)
  block_literal = block_return == "void" ? "^" : "^#{block_return}"
  nil_return = block_return == "void" ? "return;" : "return nil;"
  prefix = if method.kind == "-"
             "\n    @jobs_weakify(self)\n" \
               "    return #{block_literal}{\n" \
               "        @jobs_strongify(self)\n" \
               "        if (!self) #{nil_return}\n"
           else
             "\n    return #{block_literal}{\n"
           end
  suffix = body.empty? ? "    };\n" : "\n    };\n"
  "{#{prefix}#{body}#{suffix}}"
end

def add_edit(edits, start_offset, end_offset, replacement, label)
  edits << [start_offset, end_offset, replacement, label]
end

def selector_pattern(selectors)
  Regexp.union(selectors.sort_by { |selector| -selector.length })
end

def inside_ranges?(offset, ranges)
  ranges.any? { |start_offset, end_offset| start_offset <= offset && offset < end_offset }
end

def add_dot_call_edits(source, masked, selectors, edits, skipped_ranges = [])
  pattern = /\.\s*(#{selector_pattern(selectors)})\b(?!\s*\()/
  masked.to_enum(:scan, pattern).each do
    match = Regexp.last_match
    selector_end = match.begin(1) + match[1].bytesize
    next if inside_ranges?(selector_end, skipped_ranges)

    add_edit(edits, selector_end, selector_end, "()", "dot-call #{match[1]}")
  end
end

def add_simple_message_call_edits(source, masked, selectors, edits, skipped_ranges = [])
  selector_lookup = selectors.to_set
  stack = []
  masked.bytes.each_with_index do |byte, index|
    if byte == 91
      stack << index
    elsif byte == 93 && stack.any?
      opening = stack.pop
      next if inside_ranges?(opening, skipped_ranges)

      inner = source[(opening + 1)...index]
      message = inner.match(/\A\s*(.+?)\s+([A-Za-z_]\w*)\s*\z/m)
      next unless message

      receiver = message[1].strip
      selector = message[2]
      next unless selector_lookup.include?(selector)
      next if receiver.include?("\n") || receiver.include?(":")

      replacement = receiver.match?(/\A(?:self|super|[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\z/) ?
        "#{receiver}.#{selector}()" : "(#{receiver}).#{selector}()"
      add_edit(edits, opening, index + 1, replacement, "message-call #{selector}")
    end
  end
end

options = {
  apply: false,
  method_roots: [],
  call_roots: [],
  skip_call_selectors: []
}
OptionParser.new do |parser|
  parser.banner = "Usage: migrate_oc_zero_argument_return_type.rb [options]"
  parser.on("--return-type TYPE", "Original zero-argument method return type") { |value| options[:return_type] = value }
  parser.on("--block-type TYPE", "JobsBlock typedef used as the method return type") { |value| options[:block_type] = value }
  parser.on("--block-return TYPE", "Concrete return type written on the Block literal") { |value| options[:block_return] = value }
  parser.on("--method-root PATH", "Root containing methods to migrate; repeatable") { |value| options[:method_roots] << value }
  parser.on("--call-root PATH", "Root containing call sites to migrate; repeatable") { |value| options[:call_roots] << value }
  parser.on("--candidate-report PATH", "Audit TSV used to restrict exact path/selector candidates") { |value| options[:candidate_report] = value }
  parser.on("--skip-call-selector NAME", "Migrate the method but leave ambiguous call sites unchanged") { |value| options[:skip_call_selectors] << value }
  parser.on("--apply", "Write the verified mechanical edits") { options[:apply] = true }
end.parse!

required = %i[return_type block_type block_return]
missing = required.reject { |key| options[key] }
abort "Missing options: #{missing.join(', ')}" unless missing.empty?
abort "At least one --method-root is required" if options[:method_roots].empty?
options[:call_roots] = options[:method_roots] if options[:call_roots].empty?

sources = {}
(source_files(options[:method_roots]) | source_files(options[:call_roots])).each do |path|
  source = File.binread(path)
  next unless source.dup.force_encoding(Encoding::UTF_8).valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  sources[path] = [source, mask_non_code(source)]
end

methods = []
allowed_by_path = nil
if options[:candidate_report]
  allowed_by_path = Hash.new { |hash, key| hash[key] = Set.new }
  File.foreach(options[:candidate_report]) do |line|
    fields = line.chomp.split("\t", -1)
    next unless fields[0] == "candidate" && fields[6] == "0"

    allowed_by_path[File.expand_path(fields[1])] << fields[5]
  end
end
source_files(options[:method_roots]).each do |path|
  next unless sources[path]

  source, masked = sources.fetch(path)
  allowed_selectors = allowed_by_path && allowed_by_path[File.expand_path(path)]
  next if allowed_by_path && allowed_selectors.empty?

  methods.concat(parse_target_methods(path, source, masked, options[:return_type], allowed_selectors))
end
abort "No matching methods found" if methods.empty?

selectors = methods.map(&:selector).uniq
call_selectors = selectors - options[:skip_call_selectors]
edits_by_path = Hash.new { |hash, key| hash[key] = [] }
body_ranges_by_path = Hash.new { |hash, key| hash[key] = [] }
methods.each do |method|
  source = sources.fetch(method.path).first
  add_edit(edits_by_path[method.path], method.return_open + 1, method.return_close,
           options[:block_type], "method-return #{method.selector}")
  next unless method.body_close

  body_ranges_by_path[method.path] << [method.terminator, method.body_close + 1]
  add_edit(edits_by_path[method.path], method.terminator, method.body_close + 1,
           block_wrapped_body(method, source, options[:block_return], call_selectors), "method-body #{method.selector}")
end

source_files(options[:call_roots]).each do |path|
  next unless sources[path]

  source, masked = sources.fetch(path)
  ranges = body_ranges_by_path[path]
  add_dot_call_edits(source, masked, call_selectors, edits_by_path[path], ranges) unless call_selectors.empty?
  add_simple_message_call_edits(source, masked, call_selectors, edits_by_path[path], ranges) unless call_selectors.empty?
end

changed = 0
edits_by_path.each do |path, edits|
  next if edits.empty?

  ordered = edits.uniq.sort_by { |start_offset, end_offset, _replacement, _label| [start_offset, end_offset] }
  ordered.each_cons(2) do |left, right|
    abort "Overlapping edits in #{path}: #{left[3]} / #{right[3]}" if left[1] > right[0]
  end
  source = sources.fetch(path).first
  ordered.reverse_each do |start_offset, end_offset, replacement, _label|
    source[start_offset...end_offset] = replacement
  end
  File.binwrite(path, source) if options[:apply]
  changed += 1
  puts [options[:apply] ? "updated" : "would-update", path, ordered.length].join("\t")
end

warn "methods=#{methods.length} selectors=#{selectors.length} files=#{changed} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
