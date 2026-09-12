#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

OVERRIDES = {
  "didMoveToWindow" => "jobsDidMoveToWindow",
  "initializeData" => "jobsInitializeData",
  "initializeViews" => "jobsInitializeViews",
  "refreshDataSource" => "jobsRefreshDataSource",
}.freeze

CLASS_OVERRIDES = {
  "preferredCellClass" => "jobsPreferredCellClass",
}.freeze

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) || component.include?("Manual_Add_ThirdParty")
  end
end

def source_files(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.m"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end


def matching_brace(source, opening)
  depth = 0
  state = :code
  index = opening
  while index < source.bytesize
    current = source.getbyte(index)
    following = index + 1 < source.bytesize ? source.getbyte(index + 1) : nil
    case state
    when :code
      if current == 47 && following == 47
        state = :line_comment
        index += 2
        next
      elsif current == 47 && following == 42
        state = :block_comment
        index += 2
        next
      elsif current == 34
        state = :string
      elsif current == 39
        state = :character
      elsif current == 123
        depth += 1
      elsif current == 125
        depth -= 1
        return index if depth.zero?
      end
    when :line_comment
      state = :code if current == 10
    when :block_comment
      if current == 42 && following == 47
        state = :code
        index += 2
        next
      end
    when :string, :character
      terminal = state == :string ? 34 : 39
      if current == 92
        index += 2
        next
      elsif current == terminal
        state = :code
      end
    end
    index += 1
  end
  nil
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: restore_oc_fixed_zero_argument_overrides.rb [--apply] PATH..."
  parser.on("--apply", "Restore fixed zero-argument override ABI") { options[:apply] = true }
end.parse!

roots = ARGV.empty? ? ["."] : ARGV
changed = []

source_files(roots).each do |path|
  source = File.binread(path)
  next unless source.dup.force_encoding(Encoding::UTF_8).valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  original = source.dup
  OVERRIDES.each do |selector, facade|
    pattern = /^[ \t]*-[ \t]*\((jobsByVoidBlock[^)]*)\)[ \t]*#{Regexp.escape(selector)}[ \t]*\{/m
    while (match = source.match(pattern))
      opening = source.index("{", match.begin(0))
      closing = matching_brace(source, opening)
      break unless closing

      method = source[match.begin(0)..closing]
      facade_method = method.sub(/#{Regexp.escape(selector)}(?=\s*\{)/, facade)
      wrapper = <<~OBJC.chomp

        -(void)#{selector}{
            jobsByVoidBlock action = self.#{facade};
            if (action) action();
        }
      OBJC
      source[match.begin(0)..closing] = "#{facade_method}\n#{wrapper}"
    end
  end

  CLASS_OVERRIDES.each do |selector, facade|
    pattern = /^[ \t]*-[ \t]*\((JobsRetClassByVoidBlock[^)]*)\)[ \t]*#{Regexp.escape(selector)}[ \t]*\{/m
    while (match = source.match(pattern))
      opening = source.index("{", match.begin(0))
      closing = matching_brace(source, opening)
      break unless closing

      method = source[match.begin(0)..closing]
      facade_method = method.sub(/#{Regexp.escape(selector)}(?=\s*\{)/, facade)
      wrapper = <<~OBJC.chomp

        -(Class)#{selector}{
            JobsRetClassByVoidBlock action = self.#{facade};
            return action ? action() : Nil;
        }
      OBJC
      source[match.begin(0)..closing] = "#{facade_method}\n#{wrapper}"
    end
  end

  next if source == original

  File.binwrite(path, source) if options[:apply]
  changed << path
  puts [options[:apply] ? "updated" : "would-update", path].join("\t")
end

warn "files=#{changed.length} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
