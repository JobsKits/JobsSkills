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

IMPORT_BLOCK = <<~'OBJC'

  #if __has_include(<JobsBlock/JobsBlock.h>)
  #import <JobsBlock/JobsBlock.h>
  #else
  #import "JobsBlock.h"
  #endif
OBJC

def excluded?(path)
  path.each_filename.any? { |component| EXCLUDED_COMPONENTS.include?(component) }
end


options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: ensure_jobsblock_imports.rb [--apply] PATH..."
  parser.on("--apply", "Insert the explicit JobsBlock dual-path import") { options[:apply] = true }
end.parse!

abort "At least one path is required" if ARGV.empty?

files = ARGV.flat_map do |root|
  expanded = File.expand_path(root)
  File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.h"))
end.uniq.reject { |path| excluded?(Pathname(path)) }.sort

changed = 0
skipped = 0
files.each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)
  next unless source.match?(/^[ \t]*[-+][ \t]*\([ \t]*(?:Jobs|jobs)[A-Za-z_]\w*Blocks?\b/m)
  next if source.include?("<JobsBlock/JobsBlock.h>") ||
          source.match?(/^#import\s+["<]JobsBlock\.h[">]/)

  own_import = source.match(/^#import[^\r\n]*(?:\r?\n)/)
  unless own_import
    warn "skip-no-import\t#{path}"
    skipped += 1
    next
  end

  source.insert(own_import.end(0), IMPORT_BLOCK)
  File.binwrite(path, source) if options[:apply]
  puts [options[:apply] ? "updated" : "would-update", path].join("\t")
  changed += 1
end

warn "files=#{changed} skipped=#{skipped} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
