#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

MethodInfo = Struct.new(
  :kind, :selector, :body_open, :body_close, :return_type,
  keyword_init: true
)

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) || component.include?("Manual_Add_ThirdParty")
  end
end

def source_files(roots)
  explicit_files = roots.filter_map do |root|
    expanded = File.expand_path(root)
    expanded if File.file?(expanded)
  end
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{m,mm}"))
  end.uniq.reject do |path|
    excluded?(Pathname(path)) && !explicit_files.include?(path)
  end.sort
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

def parse_methods(source, masked, start_offset, end_offset)
  methods = []
  offset = start_offset
  pattern = /^[ \t]*([+-])[ \t]*\(/m
  while (match = masked.match(pattern, offset)) && match.begin(0) < end_offset
    opening = masked.index("(", match.begin(0))
    closing = matching_delimiter(masked, opening, 40, 41)
    break unless closing && closing < end_offset

    terminator = signature_terminator(masked, closing + 1)
    break unless terminator && terminator < end_offset

    if masked.getbyte(terminator) == 123
      body_close = matching_delimiter(masked, terminator, 123, 125)
      break unless body_close && body_close <= end_offset

      signature = source[(closing + 1)...terminator].strip.gsub(/\s+/, " ")
      methods << MethodInfo.new(
        kind: match[1],
        selector: method_selector(signature),
        body_open: terminator,
        body_close: body_close,
        return_type: source[(opening + 1)...closing].strip
      )
      offset = body_close + 1
    else
      offset = terminator + 1
    end
  end
  methods
end

def block_type?(type)
  type.match?(/\b(?:Jobs|jobs)[A-Za-z_]\w*Blocks?\b/)
end

def normalized_block_type(type)
  type.gsub(/\b_(?:Nonnull|Nullable)\b/, "").gsub(/\s+/, " ").strip
end

def direct_facade_expression(class_name, kind, block_type, facade)
  lookup = kind == "+" ? "JobsBlockClassMethodIMP" : "JobsBlockInstanceMethodIMP"
  "((#{block_type} (*)(__typeof__(self), SEL))#{lookup}(#{class_name}.class, @selector(#{facade})))" \
    "(self, @selector(#{facade}))"
end

def implementation_scopes(masked)
  scopes = []
  offset = 0
  pattern = /@implementation\s+([A-Za-z_]\w*)[^\n]*/
  while (match = masked.match(pattern, offset))
    ending = masked.match(/@end\b/, match.end(0))
    break unless ending

    scopes << [match[1], match.end(0), ending.begin(0)]
    offset = ending.end(0)
  end
  scopes
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: ensure_oc_fixed_block_trampoline_dispatch.rb [--apply] PATH..."
  parser.on("--apply", "Bind fixed-selector trampolines to their defining implementation") { options[:apply] = true }
end.parse!

abort "At least one path is required" if ARGV.empty?

changed_files = 0
changed_methods = 0
source_files(ARGV).each do |path|
  original = File.binread(path)
  next unless original.dup.force_encoding(Encoding::UTF_8).valid_encoding?
  next unless JobsOCOwnership.jobs_owned_file?(path, original)

  source = original.gsub(
    /\(\*\)\(id, SEL\)(?=\)\[[A-Za-z_]\w* (?:instanceMethodForSelector|methodForSelector):@selector\()/,
    "(*)(__typeof__(self), SEL)"
  )
  legacy_dispatches = source.scan(/\[[A-Za-z_]\w* (?:instanceMethodForSelector|methodForSelector):@selector\([A-Za-z_]\w*\)\]/).length
  source = source.gsub(
    /\[([A-Za-z_]\w*) instanceMethodForSelector:@selector\(([A-Za-z_]\w*)\)\]/,
    'JobsBlockInstanceMethodIMP(\1.class, @selector(\2))'
  ).gsub(
    /\[([A-Za-z_]\w*) methodForSelector:@selector\(([A-Za-z_]\w*)\)\]/,
    'JobsBlockClassMethodIMP(\1.class, @selector(\2))'
  )
  normalized_dispatches = legacy_dispatches
  masked = mask_non_code(source)
  edits = []
  implementation_scopes(masked).each do |class_name, scope_start, scope_end|
    methods = parse_methods(source, masked, scope_start, scope_end)
    facades = methods.each_with_object({}) do |method, result|
      next unless block_type?(method.return_type)
      next if method.selector.to_s.include?(":")

      result[[method.kind, method.selector]] = normalized_block_type(method.return_type)
    end

    methods.each do |method|
      body_start = method.body_open + 1
      body_end = method.body_close
      body = source[body_start...body_end]
      body_masked = masked[body_start...body_end]
      method_edits = []

      action_pattern = /\b((?:Jobs|jobs)[A-Za-z_]\w*Blocks?(?:\s+_(?:Nonnull|Nullable))?)\s+action\s*=\s*self\.([A-Za-z_]\w*)\s*;/
      body_masked.to_enum(:scan, action_pattern).each do
        match = Regexp.last_match
        facade = match[2]
        block_type = facades[[method.kind, facade]]
        next unless block_type

        rhs_start = body_start + match.begin(0) + match[0].index("self.#{facade}")
        rhs_end = rhs_start + "self.#{facade}".bytesize
        expression = direct_facade_expression(class_name, method.kind, block_type, facade)
        method_edits << [rhs_start, rhs_end, expression]
      end

      if method_edits.empty?
        simple = body_masked.strip
        direct_pattern = /\A(?:return\s+)?\(?self\.([A-Za-z_]\w*)\)?\s*\([^;]*\)\s*;\z/m
        if (match = simple.match(direct_pattern))
          facade = match[1]
          block_type = facades[[method.kind, facade]]
          if block_type && method.selector != facade
            relative = body.index(/self\.#{Regexp.escape(facade)}\b/)
            if relative
              rhs_start = body_start + relative
              rhs_end = rhs_start + "self.#{facade}".bytesize
              expression = "(#{direct_facade_expression(class_name, method.kind, block_type, facade)})"
              method_edits << [rhs_start, rhs_end, expression]
            end
          end
        end
      end

      changed_methods += 1 unless method_edits.empty?
      edits.concat(method_edits)
    end
  end

  next if edits.empty? && source == original

  edits.uniq.sort_by(&:first).reverse_each do |start_offset, end_offset, replacement|
    source[start_offset...end_offset] = replacement
  end
  File.binwrite(path, source) if options[:apply]
  changed_files += 1
  puts [options[:apply] ? "updated" : "would-update", path, edits.length + normalized_dispatches].join("\t")
end

warn "methods=#{changed_methods} files=#{changed_files} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
