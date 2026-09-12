#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
require "set"
require_relative "jobs_oc_ownership"

EXCLUDED_COMPONENTS = %w[
  .git Pods JobsByPods ManualByOCPods@Pods PodsManual build DerivedData
].freeze
EXCLUDED_FRAGMENTS = %w[Manual_Add_ThirdParty].freeze
UPSTREAM_ENTRY_HEADER_OVERRIDES = {
  "JXPagingView" => "JXPagerView.h",
  "Shimmer" => "FBShimmering.h",
  "XYColorOC" => "XYColorOC.h"
}.freeze

PodImport = Struct.new(:prefix, :aggregate, :internal, :source, keyword_init: true) do
  def key
    "#{prefix}/#{aggregate}"
  end

  def block
    <<~OBJC.strip
      #if __has_include(<#{key}>)
      #import <#{key}>
      #else
      #import "#{aggregate}"
      #endif
    OBJC
  end
end

class PodCatalog
  attr_reader :unresolved

  def initialize(project_root)
    @project_root = File.expand_path(project_root)
    @by_prefix = {}
    @by_aggregate = Hash.new { |hash, key| hash[key] = [] }
    @unresolved = []
    discover_target_support_files
    discover_binary_frameworks
    discover_jobs_pods
    rebuild_aggregate_index
  end

  def resolve(target)
    if target.include?("/")
      prefix, = target.split("/", 2)
      info = @by_prefix[prefix]
      return info if info&.aggregate

      return nil unless info

      @unresolved << [prefix, target, info&.source]
      return nil
    end

    matches = @by_aggregate[File.basename(target)].uniq(&:key)
    matches.one? ? matches.first : nil
  end

  private

  def discover_target_support_files
    support_root = File.join(@project_root, "Pods", "Target Support Files")
    return unless Dir.exist?(support_root)

    Dir.glob(File.join(support_root, "*", "*-umbrella.h")).sort.each do |umbrella|
      target = File.basename(File.dirname(umbrella))
      next if target.start_with?("Pods-")

      public_headers = File.binread(umbrella).scan(/^\s*#import\s+"([^"]+\.h)"/).flatten.map do |header|
        File.basename(header)
      end.uniq
      module_names = Dir.glob(File.join(File.dirname(umbrella), "*.modulemap")).flat_map do |modulemap|
        File.binread(modulemap).scan(/\b(?:framework\s+)?module\s+([A-Za-z_][A-Za-z0-9_]*)\b/).flatten
      end.uniq
      aliases = ([target] + module_names).uniq
      aggregate = UPSTREAM_ENTRY_HEADER_OVERRIDES[target]
      aggregate ||= aggregate_from_public_headers(aliases, public_headers)
      aliases.each do |prefix|
        register(PodImport.new(prefix: prefix,
                               aggregate: aggregate,
                               internal: false,
                               source: umbrella))
      end
    end
  end

  def discover_binary_frameworks
    pods_root = File.join(@project_root, "Pods")
    return unless Dir.exist?(pods_root)

    Dir.glob(File.join(pods_root, "**", "Modules", "module.modulemap")).sort.each do |modulemap|
      source = File.binread(modulemap)
      module_name = source[/\b(?:framework\s+)?module\s+([A-Za-z_][A-Za-z0-9_]*)\b/, 1]
      umbrella = source[/\bumbrella\s+header\s+"([^"]+\.h)"/, 1]
      next unless module_name && umbrella
      next if umbrella.end_with?("-umbrella.h")

      register(PodImport.new(prefix: module_name,
                             aggregate: File.basename(umbrella),
                             internal: false,
                             source: modulemap))
    end
  end

  def discover_jobs_pods
    jobs_pods_root = File.join(@project_root, "JobsByPods")
    return unless Dir.exist?(jobs_pods_root)

    Dir.glob(File.join(jobs_pods_root, "*@Pods")).sort.each do |pod_root|
      next unless File.directory?(pod_root)
      next if pod_root.include?("/ManualByOCPods@Pods/")

      prefix = File.basename(pod_root).sub(/@Pods\z/, "")
      root_headers = Dir.glob(File.join(pod_root, "*.h")).map { |path| File.basename(path) }.sort
      aggregate = aggregate_from_public_headers([prefix], root_headers)
      unless aggregate
        recursive_headers = Dir.glob(File.join(pod_root, "**", "*.h")).map { |path| File.basename(path) }.uniq
        aggregate = recursive_headers.find { |name| name.casecmp?("#{prefix}.h") }
      end
      next unless aggregate

      register(PodImport.new(prefix: prefix,
                             aggregate: aggregate,
                             internal: true,
                             source: pod_root))
    end
  end

  def aggregate_from_public_headers(aliases, headers)
    return nil if headers.empty?

    exact_names = aliases.map { |name| "#{name}.h" }
    exact_names.each do |name|
      match = headers.find { |header| header.casecmp?(name) }
      return match if match
    end

    simplified_names = aliases.flat_map do |name|
      [name.sub(/ObjC\z/i, ""), name.sub(/-ios\z/i, ""), name.sub(/Kit\z/i, "")]
    end.reject(&:empty?).uniq.map { |name| "#{name}.h" }
    simplified_names.each { |name| return name if headers.include?(name) }

    normalized_aliases = aliases.map { |name| name.gsub(/[^A-Za-z0-9]/, "").downcase }
    prefixed_headers = headers.select do |header|
      normalized_header = File.basename(header, ".h").gsub(/[^A-Za-z0-9]/, "").downcase
      normalized_aliases.any? { |name| normalized_header.start_with?(name) }
    end
    prefixed_headers.sort_by!(&:length)
    unless prefixed_headers.empty?
      return prefixed_headers.first if prefixed_headers.one? || prefixed_headers[0].length < prefixed_headers[1].length
    end

    header_candidates = headers.select { |name| name.end_with?("Header.h") }
    return header_candidates.first if header_candidates.one?
    return headers.first if headers.one?

    nil
  end

  def register(info)
    current = @by_prefix[info.prefix]
    return if current&.internal && !info.internal

    @by_prefix[info.prefix] = info
  end

  def rebuild_aggregate_index
    @by_prefix.each_value do |info|
      @by_aggregate[info.aggregate] << info if info.aggregate
    end
  end
end

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) ||
      component.end_with?(".md") ||
      EXCLUDED_FRAGMENTS.any? { |fragment| component.include?(fragment) }
  end
end

def source_files(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{h,m,mm}"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end

def body_index(lines)
  lines.index do |line|
    line.match?(/^\s*(?:NS_ASSUME_NONNULL_BEGIN\b|@(?:interface|implementation|protocol|class)\b|typedef\b|NS_INLINE\b|static\b|FOUNDATION_EXPORT\b|[A-Za-z_][^;]*;\s*$)/)
  end || lines.length
end

def header_import_insertion_index(lines)
  lines.index do |line|
    line.match?(/^\s*(?:API_(?:AVAILABLE|UNAVAILABLE|DEPRECATED)\b|#\s*(?:pragma|define|undef)\b|NS_ASSUME_NONNULL_BEGIN\b|@(?:interface|protocol|class)\b|typedef\b|NS_INLINE\b|static\b|FOUNDATION_EXPORT\b|[A-Za-z_][^;]*;\s*$)/)
  end || lines.length
end

def conditional_end(lines, start_index, limit)
  depth = 0
  (start_index...limit).each do |index|
    line = lines[index]
    depth += 1 if line.match?(/^\s*#\s*(?:if|ifdef|ifndef)\b/)
    depth -= 1 if line.match?(/^\s*#\s*endif\b/)
    return index if depth.zero?
  end
  nil
end

def import_targets(text)
  text.scan(/^\s*#import\s*[<"]([^>"]+)[>"]/).flatten
end

def simple_protective_import_block?(text)
  text.lines.all? do |line|
    stripped = line.strip
    stripped.empty? ||
      stripped.start_with?("//") ||
      stripped.match?(/\A#\s*if\s+__has_include\b/) ||
      stripped.match?(/\A#import\s*[<"]/) ||
      stripped.match?(/\A#\s*(?:else|endif)\b/)
  end
end

def strip_pod_imports(source, catalog)
  lines = source.lines
  limit = body_index(lines)
  ranges = []
  modules = Set.new
  index = 0

  while index < limit
    if lines[index].match?(/^\s*#\s*if\b.*__has_include/)
      end_index = conditional_end(lines, index, limit)
      break unless end_index

      block_text = lines[index..end_index].join
      unless simple_protective_import_block?(block_text)
        index = end_index + 1
        next
      end

      targets = import_targets(block_text)
      resolved = targets.map { |target| catalog.resolve(target) }
      if !targets.empty? && resolved.none?(&:nil?) && resolved.map(&:key).uniq.one?
        ranges << (index..end_index)
        modules << resolved.first
      end
      index = end_index + 1
      next
    end

    if (match = lines[index].match(/^\s*#import\s*[<"]([^>"]+)[>"]/))
      info = catalog.resolve(match[1])
      if info
        ranges << (index..index)
        modules << info
      end
    end
    index += 1
  end

  return [source, modules] if ranges.empty?

  ranges.reverse_each { |range| lines.slice!(range) }
  updated_limit = body_index(lines)
  prefix = lines[0...updated_limit].join.gsub(/\n{3,}/, "\n\n").rstrip
  suffix = lines[updated_limit..]&.join.to_s.lstrip
  updated = suffix.empty? ? "#{prefix}\n" : "#{prefix}\n\n#{suffix}"
  [updated, modules]
end

def module_sort_key(info)
  internal_rank = if !info.internal
                    0
                  elsif info.prefix == "JobsOCProtocols"
                    1
                  elsif %w[JobsBlock JobsOCDefs].include?(info.prefix)
                    3
                  else
                    2
                  end
  tail_rank = info.prefix == "JobsOCDefs" ? 1 : 0
  [internal_rank, tail_rank, info.prefix.downcase, info.aggregate.downcase]
end

def rebuild_header(source, modules)
  cleaned, existing_modules = yield(source)
  all_modules = (modules.to_a + existing_modules.to_a).uniq(&:key).sort_by { |info| module_sort_key(info) }
  return cleaned if all_modules.empty?

  lines = cleaned.lines
  insertion = header_import_insertion_index(lines)
  prefix = lines[0...insertion].join.gsub(/\n{3,}/, "\n\n").rstrip
  suffix = lines[insertion..]&.join.to_s.lstrip
  blocks = all_modules.map(&:block).join("\n\n")
  [prefix, blocks, suffix].reject(&:empty?).join("\n\n")
end

options = { apply: false, project_root: nil }
OptionParser.new do |parser|
  parser.banner = "Usage: ensure_oc_application_pod_imports.rb --project-root ROOT [--apply] PATH..."
  parser.on("--project-root ROOT", "Project root containing Pods and optional JobsByPods") do |root|
    options[:project_root] = root
  end
  parser.on("--apply", "Move application-layer Pod imports to same-name headers and use aggregate entry headers") do
    options[:apply] = true
  end
end.parse!

abort "--project-root is required" unless options[:project_root]
abort "At least one application-layer path is required" if ARGV.empty?

catalog = PodCatalog.new(options[:project_root])
files = source_files(ARGV)
headers = files.select { |path| File.extname(path) == ".h" }
implementations = files.select { |path| %w[.m .mm].include?(File.extname(path)) }
header_state = {}
changed_headers = 0
changed_implementations = 0
skipped_implementations = 0

headers.each do |path|
  source = File.binread(path)
  next unless source.dup.force_encoding(Encoding::UTF_8).valid_encoding?
  next unless JobsOCOwnership.jobs_owned_file?(path, source)

  cleaned, modules = strip_pod_imports(source, catalog)
  header_state[path] = { source: source, cleaned: cleaned, modules: modules }
end

implementation_updates = {}
implementations.each do |path|
  source = File.binread(path)
  next unless source.dup.force_encoding(Encoding::UTF_8).valid_encoding?
  next unless JobsOCOwnership.jobs_owned_file?(path, source)

  cleaned, modules = strip_pod_imports(source, catalog)
  next if modules.empty?

  header_path = path.sub(/\.(?:m|mm)\z/, ".h")
  state = header_state[header_path]
  unless state
    warn "skip-no-owned-header\t#{path}\t#{header_path}"
    skipped_implementations += 1
    next
  end

  state[:modules].merge(modules)
  implementation_updates[path] = [source, cleaned]
end

header_state.each do |path, state|
  updated = rebuild_header(state[:cleaned], state[:modules]) do |cleaned|
    strip_pod_imports(cleaned, catalog)
  end
  next if updated == state[:source]

  File.binwrite(path, updated) if options[:apply]
  puts [options[:apply] ? "updated-header" : "would-update-header", path, state[:modules].length].join("\t")
  changed_headers += 1
end

implementation_updates.each do |path, (source, updated)|
  next if updated == source

  File.binwrite(path, updated) if options[:apply]
  puts [options[:apply] ? "updated-implementation" : "would-update-implementation", path].join("\t")
  changed_implementations += 1
end

catalog.unresolved.uniq.each do |prefix, target, source|
  warn ["unresolved-pod-aggregate", prefix, target, source].compact.join("\t")
end
warn "headers=#{changed_headers} implementations=#{changed_implementations} skipped=#{skipped_implementations} unresolved=#{catalog.unresolved.uniq.length} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
