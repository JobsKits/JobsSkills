#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

MethodInfo = Struct.new(
  :path, :kind, :start_offset, :return_type, :signature, :selector,
  :parameter_type, :parameter_name, :terminator, :body_close, :block_type,
  :implementation_class,
  keyword_init: true
)

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) || component.include?("Manual_Add_ThirdParty")
  end
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

def parse_parameter(signature)
  colon = signature.index(":")
  return [nil, nil] unless colon

  opening = signature.index("(", colon)
  return [nil, nil] unless opening

  closing = matching_delimiter(signature, opening, 40, 41)
  return [nil, nil] unless closing

  type = signature[(opening + 1)...closing].strip
  name = signature[(closing + 1)..].to_s.strip[/\A([A-Za-z_]\w*)/, 1]
  [type, name]
end

def implementation_class_at(masked, offset)
  current = nil
  masked[0...offset].to_enum(:scan, /@implementation\s+([A-Za-z_]\w*)|@end\b/).each do
    match = Regexp.last_match
    current = match[1] || nil
  end
  current
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
    labels = signature.scan(/\b([A-Za-z_]\w*)\s*:/).flatten
    selector = labels.empty? ? signature[/\A([A-Za-z_]\w*)\b/, 1] : "#{labels.join(':')}:"
    block_type = plans[[match[1], selector]]
    if block_type
      parameter_type, parameter_name = parse_parameter(signature)
      body_close = masked.getbyte(terminator) == 123 ? matching_delimiter(masked, terminator, 123, 125) : nil
      methods << MethodInfo.new(
        path: path,
        kind: match[1],
        start_offset: match.begin(0),
        return_type: source[(opening + 1)...closing].strip,
        signature: source[match.begin(0)...terminator],
        selector: selector,
        parameter_type: parameter_type,
        parameter_name: parameter_name,
        terminator: terminator,
        body_close: body_close,
        block_type: block_type,
        implementation_class: implementation_class_at(masked, match.begin(0))
      )
    end
    body_close = masked.getbyte(terminator) == 123 ? matching_delimiter(masked, terminator, 123, 125) : nil
    offset = body_close ? body_close + 1 : terminator + 1
  end
  methods
end

def facade_selector(selector)
  base = selector.delete_suffix(":")
  "jobs#{base[0].upcase}#{base[1..]}"
end

def object_return?(type)
  type.include?("*") || type.match?(/\b(?:id|instancetype|Class)\b/)
end

def fallback_expression(type)
  normalized = type.gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__kindof)\b/, "").strip
  return "nil" if object_return?(normalized)
  return "Nil" if normalized == "Class"
  return "NO" if normalized == "BOOL"

  "(#{normalized}){0}"
end

def literal_return(type)
  return "" if %w[void IBAction].include?(type.gsub(/\s+/, ""))

  type.gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable)\b/, "")
      .gsub(/\binstancetype\b/, "id")
      .gsub(/\s+/, " ").strip
end

def indented_body(body)
  value = body.sub(/\A\r?\n/, "").sub(/\r?\n[ \t]*\z/, "")
  lines = value.lines
  common_indent = lines.reject { |line| line.strip.empty? }
                       .map { |line| line[/\A[ \t]*/].to_s.length }
                       .min.to_i
  formatted = lines.map do |line|
    next line if line.strip.empty?

    "        #{line.sub(/\A[ \t]{0,#{common_indent}}/, '')}"
  end.join
  formatted << "\n" unless formatted.empty? || formatted.end_with?("\n")
  formatted
end

def declaration(method)
  "\n#{method.kind}(#{method.block_type})#{facade_selector(method.selector)};"
end

def definition(method, source)
  facade = facade_selector(method.selector)
  parameterized = method.selector.end_with?(":")
  parameter = parameterized ? method.parameter_name : nil
  abort "Unable to parse parameter in #{method.path}: #{method.signature}" if parameterized && parameter.to_s.empty?

  return_type = method.return_type.gsub(/\s+/, "")
  void_return = %w[void IBAction].include?(return_type)
  invocation = parameterized ? "action(#{parameter})" : "action()"
  normalized_block_type = method.block_type.gsub(/\b_(?:Nonnull|Nullable)\b/, "").gsub(/\s+/, " ").strip
  lookup = method.kind == "+" ? "JobsBlockClassMethodIMP" : "JobsBlockInstanceMethodIMP"
  implementation_class = method.implementation_class
  abort "Unable to resolve implementation class in #{method.path}: #{method.signature}" unless implementation_class
  facade_dispatch = "((#{normalized_block_type} (*)(__typeof__(self), SEL))#{lookup}(#{implementation_class}.class, @selector(#{facade})))" \
                    "(self, @selector(#{facade}))"
  wrapper_body = if void_return
                   "{\n    #{method.block_type} action = #{facade_dispatch};\n    if (action) #{invocation};\n}"
                 else
                   "{\n    #{method.block_type} action = #{facade_dispatch};\n    return action ? #{invocation} : #{fallback_expression(method.return_type)};\n}"
                 end

  original_body = source[(method.terminator + 1)...method.body_close]
  original_body = original_body.gsub(/\b_cmd\b/, "@selector(#{method.selector})")
  body = indented_body(original_body)
  parameter_literal = parameterized ? "(#{method.parameter_type} #{parameter})" : ""
  block_literal = "^#{literal_return(method.return_type)}#{parameter_literal}"
  guard_return = void_return ? "return;" : "return #{fallback_expression(method.return_type)};"
  capture = if method.kind == "-"
              "    @jobs_weakify(self)\n" \
                "    return #{block_literal}{\n" \
                "        @jobs_strongify(self)\n" \
                "        if (!self) #{guard_return}\n"
            else
              "    return #{block_literal}{\n"
            end
  facade_method = "#{method.kind}(#{method.block_type})#{facade}{\n#{capture}#{body}    };\n}"
  "#{method.signature}#{wrapper_body}\n\n#{facade_method}"
end

options = { apply: false, reports: [], roots: [] }
OptionParser.new do |parser|
  parser.banner = "Usage: migrate_oc_fixed_block_facades.rb [options]"
  parser.on("--coverage PATH", "Matched coverage TSV; repeatable") { |value| options[:reports] << value }
  parser.on("--root PATH", "Jobs-owned method root; repeatable") { |value| options[:roots] << value }
  parser.on("--apply", "Write edits") { options[:apply] = true }
end.parse!

abort "At least one --coverage is required" if options[:reports].empty?
abort "At least one --root is required" if options[:roots].empty?

plans_by_path = Hash.new { |hash, key| hash[key] = {} }
options[:reports].each do |report|
  File.foreach(report) do |line|
    fields = line.chomp.split("\t", -1)
    next unless fields[0] == "matched"

    plans_by_path[File.expand_path(fields[1])][[fields[4], fields[5]]] = fields[10]
  end
end

allowed_roots = options[:roots].map { |root| File.expand_path(root) }
changed = []
method_count = 0
plans_by_path.each do |path, plans|
  next unless allowed_roots.any? { |root| path == root || path.start_with?("#{root}/") }
  explicit_file = allowed_roots.include?(path) && File.file?(path)
  next if (excluded?(Pathname(path)) && !explicit_file) || !File.file?(path)

  source = File.binread(path)
  next unless source.dup.force_encoding(Encoding::UTF_8).valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  methods = parse_methods(path, source, mask_non_code(source), plans)
  next if methods.empty?

  edits = methods.map do |method|
    replacement = method.body_close ? definition(method, source) : "#{method.signature};#{declaration(method)}"
    ending = method.body_close ? method.body_close + 1 : method.terminator + 1
    [method.start_offset, ending, replacement]
  end
  edits.sort_by(&:first).reverse_each do |start_offset, end_offset, replacement|
    source[start_offset...end_offset] = replacement
  end
  File.binwrite(path, source) if options[:apply]
  method_count += methods.length
  changed << path
  puts [options[:apply] ? "updated" : "would-update", path, methods.length].join("\t")
end

warn "methods=#{method_count} files=#{changed.length} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
