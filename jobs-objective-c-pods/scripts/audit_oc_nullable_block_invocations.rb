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
  build
  DerivedData
].freeze

DEFAULT_SELECTORS = %w[
  jobsStop
  pause
  resume
  stopAndReset
  byPauseTextScroll
  byResumeTextScroll
  byStopTextScroll
].freeze

DEFAULT_NONNULL_RECEIVER_GETTERS = %w[
  jobs_scrollController
].freeze

def excluded?(path)
  path.each_filename.any? { |component| EXCLUDED_COMPONENTS.include?(component) }
end

options = { selectors: [], nonnull_receiver_getters: [], apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: audit_oc_nullable_block_invocations.rb [--selector NAME] [--nonnull-receiver-getter NAME] [--apply] PATH..."
  parser.on("--selector NAME", "Block selector to audit; repeatable") do |selector|
    options[:selectors] << selector
  end
  parser.on("--nonnull-receiver-getter NAME", "Known nonnull Block getter result; repeatable") do |getter|
    options[:nonnull_receiver_getters] << getter
  end
  parser.on("--apply", "Guard simple property / ivar receivers before invoking their Block") do
    options[:apply] = true
  end
end.parse!

abort "At least one path is required" if ARGV.empty?

selectors = options[:selectors].empty? ? DEFAULT_SELECTORS : options[:selectors]
selector_pattern = Regexp.union(selectors)
nonnull_receiver_getters = DEFAULT_NONNULL_RECEIVER_GETTERS + options[:nonnull_receiver_getters]
simple_receiver_pattern = /self(?:\.[A-Za-z_]\w*)+|_[A-Za-z_]\w*/
nested_receiver_pattern = /\(?\s*self(?:\.[A-Za-z_]\w*\s*\(\s*\))+\s*\)?/
receiver_pattern = /(?<receiver>#{nested_receiver_pattern}|#{simple_receiver_pattern})/
files = ARGV.flat_map do |root|
  expanded = File.expand_path(root)
  File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{m,mm}"))
end.uniq.reject { |path| excluded?(Pathname(path)) }.sort

candidates = 0
updated_files = 0
files.each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  lines = utf8.lines
  file_changed = false
  lines.each_with_index do |line, index|
    edits = []
    line.to_enum(:scan, /#{receiver_pattern}\.(?<selector>#{selector_pattern})\s*\(/).each do
      match = Regexp.last_match
      prefix = line[0...match.begin(0)]
      receiver = match[:receiver]
      receiver_getters = receiver.scan(/\.([A-Za-z_]\w*)\s*\(\s*\)/).flatten
      next if receiver_getters.any? { |getter| nonnull_receiver_getters.include?(getter) }

      guarded_inline = prefix.match?(/\bif\s*\(\s*#{Regexp.escape(receiver)}\s*\)\s*\z/)
      previous = lines[[index - 2, 0].max...index].join
      guarded_previously = previous.match?(/if\s*\(\s*!\s*#{Regexp.escape(receiver)}\s*\)\s*return\b/) ||
                           previous.match?(/if\s*\(\s*#{Regexp.escape(receiver)}\s*\)\s*\{[^{}]*\z/m)
      next if guarded_inline || guarded_previously

      simple_receiver = receiver.match?(/\A#{simple_receiver_pattern}\z/)
      if options[:apply] && simple_receiver && !prefix.include?("?")
        edits << [match.begin(0), "if (#{receiver}) "]
      end

      puts [path, index + 1, receiver, match[:selector], line.strip].join("\t")
      candidates += 1
    end
    edits.sort_by(&:first).reverse_each do |offset, insertion|
      line.insert(offset, insertion)
      file_changed = true
    end
    lines[index] = line
  end
  if options[:apply] && file_changed
    File.binwrite(path, lines.join)
    updated_files += 1
  end
end

warn "candidates=#{candidates} updated_files=#{updated_files} files=#{files.length} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
