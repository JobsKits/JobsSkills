#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"

BLOCK_TYPE = "JobsRetURLManagerModelByVoidBlock"
FACADE_PREFIX = "jobs_"
EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

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


options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: restore_oc_url_manager_block_compatibility.rb [--apply] PATH..."
  parser.on("--apply", "Restore URL manager ABI and write Jobs block facades") { options[:apply] = true }
end.parse!

roots = ARGV.empty? ? ["."] : ARGV
files = source_files(roots)
owned_sources = files.to_h do |path|
  source = File.binread(path)
  valid = source.dup.force_encoding(Encoding::UTF_8).valid_encoding?
  [path, valid && JobsOCOwnership.jobs_owned_file?(path, source) ? source : nil]
end.compact

selector_pattern = /^[ \t]*[+-][ \t]*\(#{BLOCK_TYPE}[^)]*\)[ \t]*([A-Za-z_][A-Za-z0-9_]*)\b/
selectors = owned_sources.values.flat_map do |source|
  source.scan(selector_pattern).flatten.reject { |selector| selector.start_with?(FACADE_PREFIX) }
end.uniq.sort

changed = []
owned_sources.each do |path, source|
  original = source.dup

  selectors.each do |selector|
    facade = "#{FACADE_PREFIX}#{selector}"
    if File.extname(path) == ".h"
      source.gsub!(
        /^([ \t]*)([+-])[ \t]*\((#{BLOCK_TYPE}[^)]*)\)[ \t]*#{Regexp.escape(selector)}[ \t]*;/,
        "\\1\\2(URLManagerModel *_Nullable)#{selector};\n\\1\\2(\\3)#{facade};"
      )
    else
      source.gsub!(
        /^([ \t]*)([+-])[ \t]*\((#{BLOCK_TYPE}[^)]*)\)[ \t]*#{Regexp.escape(selector)}[ \t]*\{/,
        "\\1\\2(URLManagerModel *_Nullable)#{selector}{\n\\1    return self.#{facade}();\n\\1}\n\n\\1\\2(\\3)#{facade}{"
      )
    end

    source.gsub!(/\.#{Regexp.escape(selector)}[ \t]*\(\)/, ".#{facade}()")
  end

  next if source == original

  File.binwrite(path, source) if options[:apply]
  changed << path
  puts [options[:apply] ? "updated" : "would-update", path].join("\t")
end

warn "selectors=#{selectors.length} files=#{changed.length} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
