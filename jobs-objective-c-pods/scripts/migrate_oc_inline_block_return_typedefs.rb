#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "optparse"
require "pathname"
require "set"
require_relative "jobs_oc_ownership"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

FORWARD_BEGIN = "// JOBS_INLINE_BLOCK_FORWARD_AUTOGEN_BEGIN"
FORWARD_END = "// JOBS_INLINE_BLOCK_FORWARD_AUTOGEN_END"
RETURN_BEGIN = "// JOBS_INLINE_BLOCK_RETURN_TYPEDEF_AUTOGEN_BEGIN"
RETURN_END = "// JOBS_INLINE_BLOCK_RETURN_TYPEDEF_AUTOGEN_END"
VOID_BEGIN = "// JOBS_INLINE_BLOCK_VOID_TYPEDEF_AUTOGEN_BEGIN"
VOID_END = "// JOBS_INLINE_BLOCK_VOID_TYPEDEF_AUTOGEN_END"
NON_CLASS_FORWARD_NAMES = %w[
  BOOL CGFloat NSInteger NSUInteger NSTimeInterval double float int long short unsigned void
].to_set.freeze

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

def split_arguments(arguments)
  values = []
  start = 0
  round = 0
  angle = 0
  square = 0
  arguments.bytes.each_with_index do |byte, index|
    case byte
    when 40 then round += 1
    when 41 then round -= 1
    when 60 then angle += 1
    when 62 then angle -= 1
    when 91 then square += 1
    when 93 then square -= 1
    when 44
      next unless round.zero? && angle.zero? && square.zero?
      values << arguments[start...index]
      start = index + 1
    end
  end
  values << arguments[start..]
  values
end

def parameter_type(argument)
  value = argument.to_s.strip
  return "void" if value.empty? || value == "void"
  return value if value.include?("(^")

  without_name = value.sub(/\b[A-Za-z_]\w*\s*\z/, "").strip
  without_name.empty? ? value : without_name
end

def normalize_type(type)
  type.to_s
      .gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__nonnull|__nullable|__kindof)\b/, "")
      .gsub(/\b(?:__autoreleasing|__strong|__weak|__unsafe_unretained|const|volatile|NS_NOESCAPE)\b/, "")
      .gsub(/\binstancetype\b/, "id")
      .gsub(/\s+/, "")
end

def nullable_return(type)
  value = type.to_s.gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__nonnull|__nullable)\b/, "")
  value = value.gsub(/\binstancetype\b/, "id").gsub(/\s+/, " ").strip
  value.include?("*") ? "#{value} _Nullable" : value
end

def canonical_parameter(type)
  value = type.to_s.gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__nonnull|__nullable|NS_NOESCAPE)\b/, "")
  value = value.gsub(/\s+/, " ").strip
  (value.include?("*") || value.match?(/\A(?:id|Class)\b/)) && !value.include?("(^") ? "#{value} _Nullable" : value
end

def parameter_declaration(type, name = "data")
  value = type.to_s.strip
  block = value.match(/\A(.+?)\(\s*\^\s*(?:_Nonnull|_Nullable|nonnull|nullable|__nonnull|__nullable)?\s*\)\s*\((.*)\)\s*\z/m)
  if block
    return "#{block[1].strip} (^ _Nullable #{name})(#{block[2].strip})"
  end
  "#{canonical_parameter(value)} #{name}"
end

def type_stem(type)
  normalized = normalize_type(type)
  return "Void" if normalized.empty? || normalized == "void"
  return "ID" if normalized == "id"

  value = normalized.scan(/[A-Za-z_]\w*/).reject { |token| %w[const struct enum].include?(token) }
                    .map { |token| token == "id" ? "ID" : token.sub(/\A_+/, "") }
                    .reject(&:empty?).join
  value = "Type" if value.empty?
  value.length > 72 ? "#{value[0, 56]}#{Digest::SHA1.hexdigest(normalized)[0, 10]}" : value
end

def parse_inline_block(return_type)
  match = return_type.strip.match(/\A(.+?)\(\s*\^\s*(?:_Nonnull|_Nullable|nonnull|nullable|__nonnull|__nullable)?\s*\)\s*\((.*)\)\s*\z/m)
  return nil unless match

  arguments = match[2].strip
  values = arguments.empty? || arguments == "void" ? [] : split_arguments(arguments)
  return nil if values.length > 1

  parameter = values.empty? ? "void" : parameter_type(values.first)
  [match[1].strip, parameter]
end

def existing_typedefs(roots)
  entries = {}
  names = Set.new
  roots.flat_map { |root| Dir.glob(File.join(File.expand_path(root), "**", "*.h")) }.uniq.sort.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    source.scan(/typedef\b.*?;/m).each do |statement|
      match = statement.match(/\A\s*typedef\s+(.+?)\(\s*\^\s*([A-Za-z_]\w*)\s*\)\s*\((.*)\)\s*;/m)
      next unless match
      values = match[3].strip == "void" ? [] : split_arguments(match[3])
      next if values.length > 1
      parameter = values.empty? ? "void" : parameter_type(values.first)
      key = [normalize_type(match[1]), normalize_type(parameter)]
      entries[key] ||= match[2]
      names << match[2]
    end
  end
  [entries, names]
end

def block_aliases(roots)
  aliases = {}
  source_files(roots).each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    source.scan(/typedef\b.*?;/m).each do |statement|
      match = statement.match(/\A\s*typedef\s+(.+?)\(\s*\^\s*([A-Za-z_]\w*)\s*\)\s*\((.*)\)\s*;/m)
      next unless match
      aliases[match[2]] ||= "#{match[1].strip} (^)(#{match[3].strip})"
    end
  end
  aliases
end

def expanded_parameter(type, aliases, globally_available_names)
  alias_name = type.to_s.gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__nonnull|__nullable|NS_NOESCAPE)\b/, "")
                   .gsub(/\s+/, "").strip
  return type if globally_available_names.include?(alias_name)
  aliases.fetch(alias_name, type)
end

def enum_declarations(roots)
  declarations = {}
  source_files(roots).each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    source.scan(/typedef\s+NS_(ENUM|OPTIONS)\s*\(\s*([^,]+),\s*([A-Za-z_]\w*)\s*\)/) do |kind, base, name|
      declarations[name] ||= "typedef NS_#{kind}(#{base.strip}, #{name});"
    end
  end
  declarations
end

def existing_section_lines(source, begin_marker, end_marker)
  match = source.match(/#{Regexp.escape(begin_marker)}\n?(.*?)\n?#{Regexp.escape(end_marker)}/m)
  match ? match[1].lines.map(&:strip).reject(&:empty?) : []
end

def replace_generated_section(source, begin_marker, end_marker, lines)
  section = ([begin_marker] + lines.sort.uniq + [end_marker]).join("\n")
  pattern = /#{Regexp.escape(begin_marker)}.*?#{Regexp.escape(end_marker)}/m
  return source.sub(pattern, section) if source.match?(pattern)

  anchor = source.index("// JOBS_FUNCTIONAL_BLOCK_") || source.rindex(/^#endif\b/)
  abort "Unable to locate generated-section insertion point" unless anchor
  source.dup.insert(anchor, "#{section}\n\n")
end

options = {
  apply: false,
  block_roots: [],
  source_roots: [],
  forward_headers: [],
  return_headers: [],
  void_headers: []
}
OptionParser.new do |parser|
  parser.banner = "Usage: migrate_oc_inline_block_return_typedefs.rb [options] PATH..."
  parser.on("--apply", "Write typedef sections and replace inline Block method return types") { options[:apply] = true }
  parser.on("--block-root PATH", "JobsBlock root; repeatable") { |value| options[:block_roots] << value }
  parser.on("--source-root PATH", "Source root for enum and ownership resolution; repeatable") { |value| options[:source_roots] << value }
  parser.on("--forward-header PATH", "JobsBlockHeader.h target; repeatable") { |value| options[:forward_headers] << value }
  parser.on("--return-header PATH", "Return Block typedef target; repeatable") { |value| options[:return_headers] << value }
  parser.on("--void-header PATH", "Void Block typedef target; repeatable") { |value| options[:void_headers] << value }
end.parse!

abort "At least one source PATH is required" if ARGV.empty?
abort "At least one --block-root is required" if options[:block_roots].empty?
abort "--forward-header, --return-header and --void-header are required" if
  options[:forward_headers].empty? || options[:return_headers].empty? || options[:void_headers].empty?

typedefs, used_names = existing_typedefs(options[:block_roots])
globally_available_names = used_names.dup
aliases = block_aliases(options[:source_roots] | ARGV)
candidates = []
source_files(ARGV).each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  masked = mask_non_code(source)
  offset = 0
  while (match = masked.match(/^[ \t]*[+-][ \t]*\(/m, offset))
    opening = masked.index("(", match.begin(0))
    closing = matching_delimiter(masked, opening, 40, 41)
    break unless closing
    terminator = signature_terminator(masked, closing + 1)
    break unless terminator
    return_type = source[(opening + 1)...closing]
    inline = parse_inline_block(return_type)
    if inline
      signature = source[(closing + 1)...terminator].strip.gsub(/\s+/, " ")
      selector = signature[/\A([A-Za-z_]\w*)/, 1]
      candidates << [path, opening + 1, closing, inline[0], inline[1], selector, source[0...match.begin(0)].count("\n") + 1]
    end
    offset = terminator + 1
  end
end

generated = {}
candidates.each do |_path, _start, _finish, return_type, parameter_type, _selector, _line|
  key = [normalize_type(return_type), normalize_type(parameter_type)]
  next if typedefs.key?(key)
  return_stem = type_stem(return_type)
  parameter_stem = type_stem(parameter_type)
  preferred = normalize_type(return_type) == "void" ? "jobsBy#{parameter_stem}Block" : "JobsRet#{return_stem}By#{parameter_stem}Block"
  name = preferred
  if used_names.include?(name)
    digest = Digest::SHA1.hexdigest(key.join("|"))[0, 10]
    name = "#{preferred.sub(/Block\z/, "")}_#{digest}Block"
  end
  used_names << name
  typedefs[key] = name
  generated[key] = [name, return_type, expanded_parameter(parameter_type, aliases, globally_available_names)]
end

enum_map = enum_declarations(options[:source_roots] | ARGV)
class_names = Set.new
protocol_names = Set.new
enum_names = Set.new
generated.each_value do |_name, return_type, parameter_type|
  [return_type, parameter_type].each do |type|
    type.scan(/\b(?:id|NSObject)\s*<\s*([A-Za-z_]\w*)\s*>/) { |match| protocol_names << match.first }
    type.scan(/\b[A-Za-z_]\w*\b/) { |token| enum_names << token if enum_map.key?(token) }
    type.scan(/\b([A-Z][A-Za-z0-9_]*)\s*\*/) { |match| class_names << match.first }
    type.scan(/\b([A-Z][A-Za-z0-9_]*)\s*</) { |match| class_names << match.first }
  end
end

return_lines = generated.values.filter_map do |name, return_type, parameter_type|
  next if normalize_type(return_type) == "void"
  parameter = normalize_type(parameter_type) == "void" ? "void" : parameter_declaration(parameter_type)
  "typedef #{nullable_return(return_type)}(^#{name})(#{parameter});"
end
void_lines = generated.values.filter_map do |name, return_type, parameter_type|
  next unless normalize_type(return_type) == "void"
  parameter = normalize_type(parameter_type) == "void" ? "void" : parameter_declaration(parameter_type)
  "typedef void(^#{name})(#{parameter});"
end
forward_lines = enum_names.map { |name| enum_map.fetch(name) } +
                class_names.map { |name| "@class #{name};" } +
                protocol_names.map { |name| "@protocol #{name};" }

candidates.each do |path, _start, _finish, return_type, parameter_type, selector, line|
  name = typedefs.fetch([normalize_type(return_type), normalize_type(parameter_type)])
  puts ["inline-block", path, line, selector, return_type.gsub(/\s+/, " ").strip,
        parameter_type.gsub(/\s+/, " ").strip, name].join("\t")
end
warn "inline_blocks=#{candidates.length} generated_typedefs=#{generated.length} files=#{candidates.map(&:first).uniq.length} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
exit 0 unless options[:apply]

edits_by_path = Hash.new { |hash, path| hash[path] = [] }
candidates.each do |path, start_offset, end_offset, return_type, parameter_type, _selector, _line|
  name = typedefs.fetch([normalize_type(return_type), normalize_type(parameter_type)])
  edits_by_path[path] << [start_offset, end_offset, "#{name} _Nonnull"]
end
edits_by_path.each do |path, edits|
  source = File.binread(path)
  edits.sort_by(&:first).reverse_each { |start_offset, end_offset, replacement| source[start_offset...end_offset] = replacement }
  File.binwrite(path, source)
end

options[:forward_headers].each do |path|
  source = File.binread(path)
  retained = existing_section_lines(source, FORWARD_BEGIN, FORWARD_END).reject do |line|
    match = line.match(/\A@class\s+([A-Za-z_]\w*);\z/)
    match && NON_CLASS_FORWARD_NAMES.include?(match[1])
  end
  File.binwrite(path, replace_generated_section(source, FORWARD_BEGIN, FORWARD_END, retained + forward_lines))
end
options[:return_headers].each do |path|
  source = File.binread(path)
  lines = existing_section_lines(source, RETURN_BEGIN, RETURN_END) + return_lines
  File.binwrite(path, replace_generated_section(source, RETURN_BEGIN, RETURN_END, lines))
end
options[:void_headers].each do |path|
  source = File.binread(path)
  lines = existing_section_lines(source, VOID_BEGIN, VOID_END) + void_lines
  File.binwrite(path, replace_generated_section(source, VOID_BEGIN, VOID_END, lines))
end
