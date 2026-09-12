#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
require_relative "jobs_oc_ownership"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze
EXCLUDED_FRAGMENTS = %w[Manual_Add_ThirdParty].freeze

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
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{m,mm}"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end

def conditional_end(lines, start_index)
  depth = 0
  lines.each_index.drop(start_index).each do |index|
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

def already_visible?(header_targets, block_targets)
  block_targets.any? do |target|
    next true if header_targets.include?(target)
    next false unless target.include?("/")

    module_name = target.split("/", 2).first
    header_targets.include?("#{module_name}/#{module_name}.h")
  end
end

def header_insertion_index(lines)
  preferred = lines.index { |line| line.match?(/^\s*#if\s+__has_include\(<JobsBlock\//) }
  preferred ||= lines.index { |line| line.match?(/^\s*#if\s+__has_include\(<JobsOCDefs\//) }
  preferred ||= lines.index { |line| line.match?(/^\s*NS_ASSUME_NONNULL_BEGIN\b/) }
  preferred ||= lines.index { |line| line.match?(/^\s*@(?:interface|protocol|class)\b/) }
  preferred || lines.length
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: ensure_oc_protective_imports.rb [--apply] PATH..."
  parser.on("--apply", "Move top-level __has_include import blocks from implementations to same-name headers") do
    options[:apply] = true
  end
end.parse!

abort "At least one path is required" if ARGV.empty?

changed_headers = 0
changed_implementations = 0
skipped = 0

source_files(ARGV).each do |path|
  source = File.binread(path)
  next unless source.dup.force_encoding(Encoding::UTF_8).valid_encoding?
  next unless JobsOCOwnership.jobs_owned_file?(path, source)

  header_path = path.sub(/\.(?:m|mm)\z/, ".h")
  lines = source.lines
  first_body = lines.index { |line| line.match?(/^\s*(?:@interface|@implementation|NS_ASSUME_NONNULL_BEGIN|typedef\b|static\b)/) } || lines.length
  ranges = []
  index = 0
  while index < first_body
    unless lines[index].match?(/^\s*#\s*if\b.*__has_include/)
      index += 1
      next
    end

    end_index = conditional_end(lines, index)
    break unless end_index
    text = lines[index..end_index].join
    ranges << [index, end_index, text] if text.match?(/^\s*#import\b/m)
    index = end_index + 1
  end
  next if ranges.empty?

  unless File.file?(header_path)
    warn "skip-no-header\t#{path}"
    skipped += 1
    next
  end
  header = File.binread(header_path)
  unless JobsOCOwnership.jobs_owned_file?(header_path, header)
    warn "skip-header-ownership\t#{header_path}"
    skipped += 1
    next
  end

  header_targets = import_targets(header)
  blocks_to_insert = []
  ranges.each do |_start_index, _end_index, text|
    targets = import_targets(text)
    next if already_visible?(header_targets, targets)

    normalized = text.strip
    normalized_targets = import_targets(normalized)
    next if already_visible?(header_targets, normalized_targets)

    blocks_to_insert << normalized
    header_targets.concat(normalized_targets)
  end

  updated_lines = lines.dup
  ranges.reverse_each { |start_index, end_index, _text| updated_lines.slice!(start_index..end_index) }
  updated_source = updated_lines.join
  updated_source.sub!(/(\A(?:.*?\r?\n)*?#import[^\r\n]*\r?\n)\s*\r?\n+/m, "\\1\n")

  updated_header = header.dup
  unless blocks_to_insert.empty?
    header_lines = header.lines
    insertion = header_insertion_index(header_lines)
    payload = blocks_to_insert.join("\n\n") + "\n\n"
    header_lines.insert(insertion, payload)
    updated_header = header_lines.join
  end

  if updated_header != header
    File.binwrite(header_path, updated_header) if options[:apply]
    puts [options[:apply] ? "updated-header" : "would-update-header", header_path, blocks_to_insert.length].join("\t")
    changed_headers += 1
  end
  if updated_source != source
    File.binwrite(path, updated_source) if options[:apply]
    puts [options[:apply] ? "updated-implementation" : "would-update-implementation", path, ranges.length].join("\t")
    changed_implementations += 1
  end
end

warn "headers=#{changed_headers} implementations=#{changed_implementations} skipped=#{skipped} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
