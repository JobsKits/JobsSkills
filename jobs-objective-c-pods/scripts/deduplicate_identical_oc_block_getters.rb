#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
require_relative "jobs_oc_ownership"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

Definition = Struct.new(
  :owner, :kind, :selector, :path, :start_offset, :end_offset, :line, :body_key, :module_key,
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
        index += 1; state = :string
      elsif current == "'"
        index += 1; state = :character
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
        index += 2
      elsif current == terminal
        index += 1; state = :code
      else
        index += 1
      end
    end
  end
  continuing_directive = false
  masked.lines.map do |line|
    directive = continuing_directive || line.lstrip.start_with?("#")
    continuing_directive = directive && line.sub(/\r?\n\z/, "").rstrip.end_with?("\\")
    directive ? line.gsub(/[^\r\n]/, " ") : line
  end.join
end

def block_return?(return_type)
  return_type.match?(/\b(?:Jobs|jobs)[A-Za-z_]\w*Blocks?\b/) ||
    return_type.match?(/\b\w+_block_t\b/)
end

def line_number(source, offset)
  source.byteslice(0...offset).count("\n") + 1
end

def method_end(masked, opening_brace)
  depth = 1
  cursor = opening_brace + 1
  while cursor < masked.bytesize && depth.positive?
    byte = masked.getbyte(cursor)
    depth += 1 if byte == 123
    depth -= 1 if byte == 125
    cursor += 1
  end
  return nil if depth.positive?
  cursor += 1 while cursor < masked.bytesize && [10, 13].include?(masked.getbyte(cursor))
  cursor
end

def canonical_rank(definition)
  path = definition.path.tr("\\", "/")
  basename = File.basename(path, File.extname(path))
  main_owner = basename == definition.owner
  exact_owner_dsl = basename == "#{definition.owner}+DSL"
  system_supplement = path.include?("/JobsSystemAPIDSLSupplement/")
  model_dsl = path.include?("/JobsModelDSL/")
  in_jobs_dsl = path.include?("/JobsOCDSL/")
  jobsblock_owner = path.include?("/OCBaseConfig/JobsBlock/Core/Tools/")
  specialized_owner = path.include?("/NSString+Replace/")
  ownership_rank = if exact_owner_dsl || system_supplement || model_dsl || jobsblock_owner || specialized_owner
                     0
                   elsif main_owner || in_jobs_dsl
                     1
                   else
                     2
                   end
  [ownership_rank, path.length, path, definition.line]
end

def module_key(path)
  normalized = path.tr("\\", "/")
  match = normalized.match(%r{/JobsByPods/([^/]+@Pods)/})
  match ? "pod:#{match[1]}" : "host"
end

options = { apply: false, cross_module: false, canonicalize: false }
OptionParser.new do |parser|
  parser.banner = "Usage: deduplicate_identical_oc_block_getters.rb [--apply] PATH..."
  parser.on("--apply", "Remove byte-equivalent duplicate Block getter implementations") { options[:apply] = true }
  parser.on("--cross-module", "Allow removals across local Pod or host module boundaries after dependency review") do
    options[:cross_module] = true
  end
  parser.on("--canonicalize", "Remove non-identical duplicates in favor of the ranked real owner") do
    options[:canonicalize] = true
  end
end.parse!

abort "At least one path is required" if ARGV.empty?

sources = {}
definitions = []
source_files(ARGV).each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  sources[path] = source
  masked = mask_non_code(source)
  implementation_offset = 0
  while (implementation = masked.match(/@implementation\s+([A-Za-z_]\w*)(?:\s*\([^)]*\))?/, implementation_offset))
    owner = implementation[1]
    implementation_end = masked.index(/@end\b/, implementation.end(0))
    break unless implementation_end

    region = masked.byteslice(implementation.end(0)...implementation_end)
    region.to_enum(:scan, /^[ \t]*([+-])[ \t]*\(([^\r\n()]*)\)[ \t]*([A-Za-z_]\w*)[ \t\r\n]*(?:(?:API|NS|UI)_[A-Z0-9_]+[ \t]*\([^;{}]*\)[ \t\r\n]*)*\{/m).each do
      method = Regexp.last_match
      next unless block_return?(method[2])

      start_offset = implementation.end(0) + method.begin(0)
      opening_brace = implementation.end(0) + method.end(0) - 1
      end_offset = method_end(masked, opening_brace)
      next unless end_offset && end_offset <= implementation_end

      body = masked.byteslice(opening_brace...end_offset).gsub(/\s+/, "")
      body = body.gsub(/self\.([a-z][A-Za-z0-9_]*)=([^;]+);/) do
        property = Regexp.last_match(1)
        value = Regexp.last_match(2)
        "[selfset#{property[0].upcase}#{property[1..]}:#{value}];"
      end
      definitions << Definition.new(
        owner: owner,
        kind: method[1],
        selector: method[3],
        path: path,
        start_offset: start_offset,
        end_offset: end_offset,
        line: line_number(source, start_offset),
        body_key: body,
        module_key: module_key(path)
      )
    end
    implementation_offset = implementation_end + 4
  end
end

duplicate_groups = definitions.group_by { |entry| [entry.owner, entry.kind, entry.selector] }
                              .select { |_key, entries| entries.length > 1 }
removals = []
remaining = []

duplicate_groups.sort.each do |(owner, kind, selector), entries|
  body_groups = entries.group_by(&:body_key)
  body_groups.each_value do |same_body|
    scoped_groups = options[:cross_module] ? [same_body] : same_body.group_by(&:module_key).values
    scoped_groups.each do |scoped_body|
      next if scoped_body.length < 2
      keeper = scoped_body.min_by { |entry| canonical_rank(entry) }
      scoped_body.each do |entry|
        next if entry.equal?(keeper)
        removals << entry
        puts [options[:apply] ? "remove" : "would-remove", owner, kind, selector, entry.path, entry.line, "keep", keeper.path, keeper.line].join("\t")
      end
    end
  end
  if options[:canonicalize]
    survivors = entries.reject { |entry| removals.include?(entry) }
    scoped_groups = options[:cross_module] ? [survivors] : survivors.group_by(&:module_key).values
    scoped_groups.each do |scoped_entries|
      next if scoped_entries.length < 2
      keeper = scoped_entries.min_by { |entry| canonical_rank(entry) }
      scoped_entries.each do |entry|
        next if entry.equal?(keeper)
        removals << entry
        puts [options[:apply] ? "canonicalize" : "would-canonicalize", owner, kind, selector, entry.path, entry.line, "keep", keeper.path, keeper.line].join("\t")
      end
    end
  end
  survivors = entries.reject { |entry| removals.include?(entry) }
  remaining << [owner, kind, selector, survivors] if survivors.length > 1
end

if options[:apply]
  removals.group_by(&:path).each do |path, entries|
    updated = sources.fetch(path).dup
    entries.sort_by(&:start_offset).reverse_each do |entry|
      updated[entry.start_offset...entry.end_offset] = ""
    end
    File.binwrite(path, updated)
  end
end

remaining.each do |owner, kind, selector, entries|
  puts ["remaining", owner, kind, selector, entries.length].join("\t")
  entries.sort_by { |entry| [entry.path, entry.line] }.each do |entry|
    puts ["definition", entry.path, entry.line].join("\t")
  end
end

warn "duplicate_groups=#{duplicate_groups.length} removable=#{removals.length} remaining_groups=#{remaining.length} canonicalize=#{options[:canonicalize]} cross_module=#{options[:cross_module]} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
exit 0
