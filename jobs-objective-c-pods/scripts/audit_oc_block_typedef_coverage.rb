#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"

GENERATED_SECTION_PATTERN = %r{// JOBS_FUNCTIONAL_BLOCK_(?:FORWARD|TYPEDEF)_AUTOGEN_BEGIN.*?// JOBS_FUNCTIONAL_BLOCK_(?:FORWARD|TYPEDEF)_AUTOGEN_END}m

def strip_comments(source)
  source.gsub(%r{/\*.*?\*/}m, " ").gsub(%r{//[^\n]*}, " ")
end

def normalize_type(type)
  type.to_s
      .gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__nonnull|__nullable|__kindof)\b/, "")
      .gsub(/\b(?:NS_NOESCAPE|CF_RETURNS_RETAINED|NS_RETURNS_RETAINED)\b/, "")
      .gsub(/\binstancetype\b/, "id")
      .gsub(/\*\s*[A-Za-z_]\w*(?=\s*[,\)])/, "*")
      .gsub(/\b([A-Za-z_]\w*)\s+[A-Za-z_]\w*(?=\s*[,\)])/, "\\1")
      .gsub(/\s+/, "")
end

def parameter_type(argument)
  value = argument.to_s.strip
  return "void" if value == "void" || value.empty?

  value = value.sub(/\b[A-Za-z_]\w*\s*\z/, "").strip
  value.empty? ? argument.to_s.strip : value
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
  return nil unless closing

  signature[(opening + 1)...closing].strip
end

def block_typedefs(roots, ignore_generated)
  entries = Hash.new { |hash, key| hash[key] = [] }
  roots.flat_map { |root| Dir.glob(File.join(File.expand_path(root), "**", "*.h")) }.uniq.sort.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    source = source.gsub(GENERATED_SECTION_PATTERN, "") if ignore_generated
    source = strip_comments(source)

    source.scan(/typedef\b.*?;/m).each do |statement|
      declaration = statement.match(/\A\s*typedef\s+(.+?)\(\s*\^\s*([A-Za-z_]\w*)\s*\)/m)
      next unless declaration

      return_type = declaration[1]
      name = declaration[2]
      opening = statement.index("(", declaration.end(0))
      next unless opening

      depth = 0
      closing = nil
      statement.bytes.each_with_index do |byte, index|
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
      next unless closing

      arguments = statement[(opening + 1)...closing]
      args = arguments.strip == "void" ? [] : split_arguments(arguments).map { |argument| parameter_type(argument) }
      next if args.length > 1

      key = [normalize_type(return_type), args.map { |argument| normalize_type(argument) }]
      entries[key] << [name, path, return_type.strip, args]
    end
  end
  entries
end

options = { block_roots: [], ignore_generated: false }
OptionParser.new do |parser|
  parser.banner = "Usage: audit_oc_block_typedef_coverage.rb --report audit.tsv --block-root PATH..."
  parser.on("--report PATH", "Candidate TSV from audit_oc_functional_block_apis.rb") { |value| options[:report] = value }
  parser.on("--block-root PATH", "JobsBlock root; repeatable") { |value| options[:block_roots] << value }
  parser.on("--ignore-generated", "Ignore previously generated functional typedef sections") { options[:ignore_generated] = true }
end.parse!

abort "--report is required" unless options[:report]
abort "At least one --block-root is required" if options[:block_roots].empty?

typedefs = block_typedefs(options[:block_roots], options[:ignore_generated])
counts = Hash.new(0)
counts["matched"] = 0
counts["unmatched"] = 0

File.foreach(options[:report]) do |line|
  fields = line.chomp.split("\t", -1)
  next unless fields[0] == "candidate"

  parameter_count = fields[6].to_i
  next unless parameter_count <= 1

  parameter = parameter_count.zero? ? [] : [normalize_type(method_parameter(fields[8]))]
  key = [normalize_type(fields[7]), parameter]
  matches = typedefs[key]
  if matches.empty?
    counts["unmatched"] += 1
    puts (["unmatched"] + fields[1..] + [parameter.first.to_s]).join("\t")
  else
    counts["matched"] += 1
    preferred = matches.min_by { |name, _path, _return_type, _args| [name.length, name] }
    puts (["matched"] + fields[1..] + [parameter.first.to_s, preferred[0]]).join("\t")
  end
end

warn counts.sort.map { |key, value| "#{key}=#{value}" }.join(" ")
exit(counts["unmatched"].positive? ? 2 : 0)
