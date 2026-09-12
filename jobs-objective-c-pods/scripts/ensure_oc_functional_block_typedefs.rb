#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "optparse"
require "set"
require_relative "jobs_oc_ownership"

FORWARD_BEGIN = "// JOBS_FUNCTIONAL_BLOCK_FORWARD_AUTOGEN_BEGIN"
FORWARD_END = "// JOBS_FUNCTIONAL_BLOCK_FORWARD_AUTOGEN_END"
TYPEDEF_BEGIN = "// JOBS_FUNCTIONAL_BLOCK_TYPEDEF_AUTOGEN_BEGIN"
TYPEDEF_END = "// JOBS_FUNCTIONAL_BLOCK_TYPEDEF_AUTOGEN_END"
GENERATED_SECTION_PATTERN = %r{// JOBS_FUNCTIONAL_BLOCK_(?:FORWARD|TYPEDEF)_AUTOGEN_BEGIN.*?// JOBS_FUNCTIONAL_BLOCK_(?:FORWARD|TYPEDEF)_AUTOGEN_END}m
EXTERNALLY_DEFINED_VALUE_ALIASES = Set.new(%w[ASSizeRange]).freeze

def normalize_type(type)
  type.to_s
      .gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__nonnull|__nullable|__kindof)\b/, "")
      .gsub(/\b(?:__autoreleasing|__strong|__weak|__unsafe_unretained|const|volatile)\b/, "")
      .gsub(/\binstancetype\b/, "id")
      .gsub(/\*\s*[A-Za-z_]\w*(?=\s*[,\)])/, "*")
      .gsub(/\b([A-Za-z_]\w*)\s+[A-Za-z_]\w*(?=\s*[,\)])/, "\\1")
      .gsub(/\s+/, "")
end

def block_alias_declarations(roots)
  declarations = {}
  roots.flat_map { |root| Dir.glob(File.join(File.expand_path(root), "**", "*.h")) }.uniq.sort.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?

    source.scan(/typedef\b.*?;/m).each do |statement|
      match = statement.match(/\(\s*\^\s*([A-Za-z_]\w*)\s*\)/m)
      next unless match

      declarations[match[1]] ||= statement.strip
    end
  end
  declarations
end

def type_stem(type)
  normalized = normalize_type(type)
  return "Void" if normalized.empty? || normalized == "void"
  return "ID" if normalized == "id"

  tokens = normalized.scan(/[A-Za-z_]\w*/).reject { |token| %w[const struct enum].include?(token) }
  value = tokens.map do |token|
    token == "id" ? "ID" : token.sub(/\A_+/, "")
  end.reject(&:empty?).join
  value = "Type" if value.empty?
  value.length > 72 ? "#{value[0, 56]}#{Digest::SHA1.hexdigest(normalized)[0, 10]}" : value
end

def nullable_return(type)
  value = type.gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__nonnull|__nullable)\b/, "")
  value = value.gsub(/\binstancetype\b/, "id")
  if value.include?("*")
    value = "#{value.strip} _Nullable"
  end
  value.gsub(/\s+/, " ").strip
end

def canonical_parameter(type)
  value = type.to_s
  nullability = if value.match?(/\b(?:_Nonnull|nonnull|__nonnull)\b/)
                  "_Nonnull"
                elsif value.match?(/\b(?:_Nullable|nullable|__nullable)\b/)
                  "_Nullable"
                end
  value = value.gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__nonnull|__nullable|NS_NOESCAPE)\b/, "")
               .gsub(/\s+/, " ").strip
  if nullability
    value = if value.match?(/\(\s*\^\s*\)/)
              value.sub(/\^(?=\s*\))/, "^ #{nullability}")
            else
              "#{value} #{nullability}"
            end
  end
  value
end

def method_parameter(signature)
  colon = signature.index(":")
  return nil unless colon

  opening = signature.index("(", colon)
  return nil unless opening

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
  closing ? signature[(opening + 1)...closing].strip : nil
end

def signature_from_row(fields)
  return_type = fields[7]
  parameter_type = fields[6].to_i.zero? ? "void" : method_parameter(fields[8]).to_s
  parameter_type = "void" if parameter_type.empty?
  [normalize_type(return_type), normalize_type(parameter_type), return_type, parameter_type]
end

def existing_typedef_names(roots)
  names = Set.new
  roots.flat_map { |root| Dir.glob(File.join(File.expand_path(root), "**", "*.h")) }.uniq.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    source = source.gsub(GENERATED_SECTION_PATTERN, "")

    source.scan(/typedef\b[^;]*?\(\s*\^\s*([A-Za-z_]\w*)\s*\)/m) { |match| names << match.first }
  end
  names
end

def enum_declarations(roots)
  declarations = {}
  roots.flat_map { |root| Dir.glob(File.join(File.expand_path(root), "**", "*.{h,m,mm}")) }.uniq.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?

    source.scan(/typedef\s+NS_(ENUM|OPTIONS)\s*\(\s*([^,]+),\s*([A-Za-z_]\w*)\s*\)/) do |kind, base, name|
      # Old integrated projects can contain a third-party enum and a Jobs enum
      # with the same name but different underlying types. Prefer the Jobs-owned
      # declaration so JobsBlock's forward declaration matches the public ABI.
      priority = if path.include?("/JobsOCDefs/") || path.include?("/JobsDefineEnums/")
                   0
                 elsif JobsOCOwnership.jobs_owned_file?(path, source)
                   1
                 else
                   2
                 end
      candidate = [priority, path, "typedef NS_#{kind}(#{base.strip}, #{name});"]
      declarations[name] = candidate if !declarations.key?(name) ||
                                        (candidate[0, 2] <=> declarations[name][0, 2]) == -1
    end
  end
  declarations.transform_values { |entry| entry[2] }
end

def value_alias_declarations(roots)
  declarations = {}
  roots.flat_map { |root| Dir.glob(File.join(File.expand_path(root), "**", "*.{h,m,mm}")) }.uniq.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?

    source.scan(/typedef\s+([^;{}]+?[*\s])([A-Za-z_]\w*)\s+NS_TYPED_ENUM\s*;/m) do |type, name|
      declarations[name] ||= "typedef #{type.strip} #{name} NS_TYPED_ENUM;"
    end
    source.scan(/typedef\s+struct\s*\{(.*?)\}\s*([A-Za-z_]\w*)\s*;/m) do |body, name|
      declarations[name] ||= "typedef struct {#{body}} #{name};"
    end
  end
  declarations
end

def macro_stem(name)
  name.gsub(/([a-z0-9])([A-Z])/, '\\1_\\2').upcase
end

def replace_generated_section(source, begin_marker, end_marker, lines)
  section = ([begin_marker] + lines + [end_marker]).join("\n")
  pattern = /#{Regexp.escape(begin_marker)}.*?#{Regexp.escape(end_marker)}/m
  return source.sub(pattern, section) if source.match?(pattern)

  insertion = source.rindex(/^#endif\b/)
  abort "Unable to find final #endif for generated section" unless insertion

  source.dup.insert(insertion, "#{section}\n\n")
end

options = {
  apply: false,
  reports: [],
  block_roots: [],
  source_roots: [],
  forward_headers: [],
  return_headers: [],
  void_headers: []
}
OptionParser.new do |parser|
  parser.banner = "Usage: ensure_oc_functional_block_typedefs.rb [options]"
  parser.on("--coverage PATH", "Coverage TSV; repeatable") { |value| options[:reports] << value }
  parser.on("--block-root PATH", "JobsBlock root; repeatable") { |value| options[:block_roots] << value }
  parser.on("--source-root PATH", "Source root used to resolve enum declarations; repeatable") { |value| options[:source_roots] << value }
  parser.on("--forward-header PATH", "JobsBlockHeader.h target; repeatable") { |value| options[:forward_headers] << value }
  parser.on("--return-header PATH", "Return-by-certain-parameters target; repeatable") { |value| options[:return_headers] << value }
  parser.on("--void-header PATH", "Void-by-certain-parameters target; repeatable") { |value| options[:void_headers] << value }
  parser.on("--apply", "Write generated sections") { options[:apply] = true }
end.parse!

abort "At least one --coverage is required" if options[:reports].empty?
abort "At least one --block-root is required" if options[:block_roots].empty?
abort "At least one --forward-header is required" if options[:forward_headers].empty?
abort "At least one --return-header is required" if options[:return_headers].empty?
abort "At least one --void-header is required" if options[:void_headers].empty?

rows = options[:reports].flat_map do |report|
  File.readlines(report, chomp: true).map { |line| line.split("\t", -1) }.select { |fields| fields[0] == "unmatched" }
end
signatures = rows.to_h { |fields| [signature_from_row(fields)[0, 2], signature_from_row(fields)[2, 2]] }
existing_names = existing_typedef_names(options[:block_roots])
used_names = existing_names.dup
typedefs = {}

signatures.sort.each do |(normalized_return, normalized_parameter), (return_type, parameter_type)|
  return_stem = type_stem(normalized_return)
  parameter_stem = type_stem(normalized_parameter)
  preferred = normalized_return == "void" ? "jobsBy#{parameter_stem}Block" : "JobsRet#{return_stem}By#{parameter_stem}Block"
  digest = Digest::SHA1.hexdigest("#{normalized_return}|#{normalized_parameter}")[0, 10]
  name = preferred
  name = "#{preferred.sub(/Block\z/, "")}_#{digest}Block" if used_names.include?(name)
  used_names << name
  typedefs[[normalized_return, normalized_parameter]] = [name, return_type, parameter_type]
end

class_names = Set.new
protocol_names = Set.new
alias_map = block_alias_declarations(options[:source_roots] | options[:block_roots])
required_alias_names = Set.new
value_alias_map = value_alias_declarations(options[:source_roots])
required_value_alias_names = Set.new
typedefs.each_value do |_name, return_type, parameter_type|
  [return_type, parameter_type].each do |type|
    token = normalize_type(type)
    required_alias_names << token if token.match?(/\A[A-Za-z_]\w*\z/) && alias_map.key?(token)
    required_value_alias_names << token if token.match?(/\A[A-Za-z_]\w*\z/) &&
                                          value_alias_map.key?(token) &&
                                          !EXTERNALLY_DEFINED_VALUE_ALIASES.include?(token)
    type.scan(/\b(id|Class|NSObject)\s*<\s*([A-Za-z_]\w*)\s*>/) { |_kind, protocol| protocol_names << protocol }
    type.scan(/([A-Za-z_]\w*)\s*\*/) do |match|
      token = match.first
      class_names << token if token.match?(/\A(?:[A-Z]|_)[A-Za-z0-9_]*\z/) &&
                            !%w[_Nonnull _Nullable __autoreleasing __strong __weak __unsafe_unretained].include?(token)
    end
  end
end
required_alias_names.each do |name|
  alias_map.fetch(name).scan(/([A-Za-z_]\w*)\s*\*/) do |match|
    token = match.first
    class_names << token if token.match?(/\A(?:[A-Z]|_)[A-Za-z0-9_]*\z/) &&
                          !%w[_Nonnull _Nullable __autoreleasing __strong __weak __unsafe_unretained].include?(token)
  end
end
enum_map = enum_declarations(options[:source_roots])
value_type_names = typedefs.values.flat_map { |_name, return_type, parameter_type| [return_type, parameter_type] }
                          .map { |type| normalize_type(type) }
                          .select { |type| type.match?(/\A[A-Za-z_]\w*\z/) }
                          .uniq
enum_lines = value_type_names.filter_map { |name| enum_map[name] }.sort
forward_lines = ["", "#pragma mark —— Generated Functional Block Forward Declarations"]
forward_lines.concat(class_names.sort.map { |name| "@class #{name};" })
forward_lines.concat(protocol_names.sort.map { |name| "@protocol #{name};" })
forward_lines.concat(enum_lines)
unless required_value_alias_names.empty?
  forward_lines.concat(["", "#pragma mark —— Generated Functional Value Alias Declarations"])
  required_value_alias_names.sort.each do |name|
    declaration = value_alias_map.fetch(name)
    if declaration.start_with?("typedef struct")
      guard = "JOBS_#{macro_stem(name.sub(/\AJobs/, ''))}_STRUCT_DEFINED"
      forward_lines.concat(["#ifndef #{guard}", "#define #{guard}", declaration, "#endif"])
    else
      forward_lines << declaration
    end
  end
end
unless required_alias_names.empty?
  forward_lines.concat(["", "#pragma mark —— Generated Functional Block Alias Declarations"])
  forward_lines.concat(required_alias_names.sort.map { |name| alias_map.fetch(name) })
end

return_lines = ["", "#pragma mark —— Generated Functional Return Blocks"]
void_lines = ["", "#pragma mark —— Generated Functional Void Blocks"]
typedefs.sort_by { |_signature, (name, _return_type, _parameter_type)| name }.each do |_signature, (name, return_type, parameter_type)|
  parameter = normalize_type(parameter_type) == "void" ? "void" : canonical_parameter(parameter_type)
  if normalize_type(return_type) == "void"
    void_lines << "typedef void(^#{name})(#{parameter});"
  else
    return_lines << "typedef #{nullable_return(return_type)}(^#{name})(#{parameter});"
  end
end

targets = []
options[:forward_headers].each { |path| targets << [path, FORWARD_BEGIN, FORWARD_END, forward_lines] }
options[:return_headers].each { |path| targets << [path, TYPEDEF_BEGIN, TYPEDEF_END, return_lines] }
options[:void_headers].each { |path| targets << [path, TYPEDEF_BEGIN, TYPEDEF_END, void_lines] }
changed = 0
targets.each do |path, begin_marker, end_marker, lines|
  source = File.binread(path).force_encoding(Encoding::UTF_8)
  abort "Invalid UTF-8 header: #{path}" unless source.valid_encoding?
  updated = replace_generated_section(source, begin_marker, end_marker, lines)
  next if source == updated

  File.binwrite(path, updated) if options[:apply]
  changed += 1
  puts [options[:apply] ? "updated" : "would-update", File.expand_path(path)].join("\t")
end

warn "signatures=#{typedefs.length} classes=#{class_names.length} protocols=#{protocol_names.length} enums=#{enum_lines.length} files=#{changed} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
