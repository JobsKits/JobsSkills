#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"

EXCLUDED_COMPONENTS = %w[
  .git
  Pods
  ManualByOCPods@Pods
  PodsManual
  JobsBlock
  JobsBlock@Pods
  build
  DerivedData
].freeze

IMPORT_BLOCK = <<~'OBJC'.strip
  #if __has_include(<JobsOCDefs/JobsDefines.h>)
  #import <JobsOCDefs/JobsDefines.h>
  #else
  #import "JobsDefines.h"
  #endif
OBJC

IMPORT_PATTERN = %r{
  ^[ \t]*\#if[ \t]+__has_include\(<JobsOCDefs/JobsDefines\.h>\)[ \t]*\r?\n
  [ \t]*\#import[ \t]+<JobsOCDefs/JobsDefines\.h>[ \t]*\r?\n
  [ \t]*\#else[ \t]*\r?\n
  [ \t]*\#import[ \t]+"JobsDefines\.h"[ \t]*\r?\n
  [ \t]*\#endif[ \t]*(?:\r?\n)?
}x.freeze
DIRECT_IMPORT_PATTERN = /^[ \t]*#import[ \t]+["<](?:JobsOCDefs\/)?JobsDefines\.h[">][ \t]*(?:\r?\n)?/.freeze

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

def header_files(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [] : Dir.glob(File.join(expanded, "**", "*.h"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end

def imported_header_basenames(source)
  source.scan(/^\s*#import\s*[<"]([^>"]+\.h)[>"]/).flatten.map { |target| File.basename(target) }.uniq
end

def header_path_for(implementation)
  implementation.sub(/\.(?:m|mm)\z/, ".h")
end

def insert_import_block(header)
  return header if header.match?(IMPORT_PATTERN) || header.match?(DIRECT_IMPORT_PATTERN)

  lines = header.lines
  first_import = lines.index { |line| line.match?(/^\s*#(?:import|if\s+__has_include\b)/) }
  return nil unless first_import

  index = first_import
  last_import_end = first_import
  while index < lines.length
    line = lines[index]
    if line.match?(/^\s*#import\b/)
      last_import_end = index + 1
      index += 1
    elsif line.match?(/^\s*#if\s+__has_include\b/)
      closing = (index...lines.length).find { |candidate| lines[candidate].match?(/^\s*#endif\b/) }
      return nil unless closing

      last_import_end = closing + 1
      index = closing + 1
    elsif line.strip.empty?
      index += 1
    else
      break
    end
  end

  before = lines[0...last_import_end].join.rstrip
  after = lines[last_import_end..].to_a.join.lstrip
  "#{before}\n\n#{IMPORT_BLOCK}\n\n#{after}"
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: ensure_jobsdefines_imports.rb [--apply] PATH..."
  parser.on("--apply", "Move JobsDefines dual-path imports to same-name headers") { options[:apply] = true }
end.parse!

abort "At least one path is required" if ARGV.empty?

changed_headers = 0
changed_implementations = 0
skipped = 0
headers_by_basename = header_files(ARGV).group_by { |path| File.basename(path) }

source_files(ARGV).each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  uses_macros = source.include?("@jobs_weakify") || source.include?("@jobs_strongify")
  has_import = source.match?(IMPORT_PATTERN) || source.match?(DIRECT_IMPORT_PATTERN)
  next unless uses_macros || has_import

  header_path = header_path_for(path)
  unless File.file?(header_path)
    candidates = imported_header_basenames(source).flat_map { |basename| headers_by_basename.fetch(basename, []) }.uniq
    candidates.select! do |candidate|
      candidate_source = File.binread(candidate)
      JobsOCOwnership.jobs_owned_file?(candidate, candidate_source)
    end
    already_compliant = candidates.find do |candidate|
      candidate_source = File.binread(candidate)
      candidate_source.match?(IMPORT_PATTERN) || candidate_source.match?(DIRECT_IMPORT_PATTERN)
    end
    header_path = already_compliant || (candidates.one? ? candidates.first : nil)
    unless header_path
      warn "skip-no-header\t#{path}"
      skipped += 1
      next
    end
  end

  header = File.binread(header_path)
  unless JobsOCOwnership.jobs_owned_file?(header_path, header)
    warn "skip-header-ownership\t#{header_path}"
    skipped += 1
    next
  end

  updated_header = insert_import_block(header)
  unless updated_header
    warn "skip-no-header-import-region\t#{header_path}"
    skipped += 1
    next
  end

  updated_source = source.gsub(IMPORT_PATTERN, "").gsub(DIRECT_IMPORT_PATTERN, "")
  updated_source.sub!(/(\A(?:.*?\r?\n)*?#import[^\r\n]*\r?\n)\s*\r?\n+/m, "\\1\n")

  if updated_header != header
    File.binwrite(header_path, updated_header) if options[:apply]
    puts [options[:apply] ? "updated-header" : "would-update-header", header_path].join("\t")
    changed_headers += 1
  end
  if updated_source != source
    File.binwrite(path, updated_source) if options[:apply]
    puts [options[:apply] ? "updated-implementation" : "would-update-implementation", path].join("\t")
    changed_implementations += 1
  end
end

warn "headers=#{changed_headers} implementations=#{changed_implementations} skipped=#{skipped} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
