#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"
require "set"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

Facade = Struct.new(:selector, :facade, :original_return, :fallback, :kind, keyword_init: true)

FACADES = [
  Facade.new(selector: "sharedManager", facade: "jobsSharedManager", original_return: "instancetype", fallback: "nil", kind: "+"),
  Facade.new(selector: "destroySingleton", facade: "jobsDestroySingleton", original_return: "void", fallback: nil, kind: "+"),
  Facade.new(selector: "jobsGetCurrentViewControllerWithNavCtrl", facade: "jobsGetCurrentViewControllerWithNavCtrlBlock", original_return: "__kindof UIViewController *_Nullable", fallback: "nil", kind: "-"),
  Facade.new(selector: "jobsGetCurrentViewController", facade: "jobsGetCurrentViewControllerBlock", original_return: "__kindof UIViewController *_Nullable", fallback: "nil", kind: "-"),
  Facade.new(selector: "mjHeaderDefaultConfig", facade: "jobsMjHeaderDefaultConfig", original_return: "MJRefreshConfigModel *_Nullable", fallback: "nil", kind: "-"),
  Facade.new(selector: "mjFooterDefaultConfig", facade: "jobsMjFooterDefaultConfig", original_return: "MJRefreshConfigModel *_Nullable", fallback: "nil", kind: "-"),
  Facade.new(selector: "getView", facade: "jobsGetView", original_return: "__kindof UIView *_Nullable", fallback: "nil", kind: "-"),
  Facade.new(selector: "getViewModel", facade: "jobsGetViewModel", original_return: "UIViewModel *_Nullable", fallback: "nil", kind: "-"),
  Facade.new(selector: "getButtonModel", facade: "jobsGetButtonModel", original_return: "__kindof UIButtonModel *_Nullable", fallback: "nil", kind: "-"),
  Facade.new(selector: "getInterfaceOrientation", facade: "jobsGetInterfaceOrientation", original_return: "UIInterfaceOrientation", fallback: "(UIInterfaceOrientation){0}", kind: "-")
].freeze
FIXED_PROTOCOL_RECEIVER_SELECTORS = Set.new(%w[getViewModel getButtonModel]).freeze

BLOCK_RETURN_PATTERN = /(?:Jobs|jobs)[A-Za-z_]\w*Blocks?(?:\s+_(?:Nonnull|Nullable))?/

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) || component.include?("Manual_Add_ThirdParty")
  end
end

def source_files(roots)
  explicit_files = roots.filter_map do |root|
    expanded = File.expand_path(root)
    expanded if File.file?(expanded)
  end.to_set
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    if File.file?(expanded)
      [expanded]
    else
      Dir.glob(File.join(expanded, "**", "*.{h,m,mm}"), File::FNM_EXTGLOB)
    end
  end.uniq.reject { |path| excluded?(Pathname(path)) && !explicit_files.include?(path) }.sort
end

def implementation_class_at(source, offset)
  current = nil
  source[0...offset].to_enum(:scan, /@implementation\s+([A-Za-z_]\w*)|@end\b/).each do
    match = Regexp.last_match
    current = match[1] || nil
  end
  current
end

def wrapper(facade, block_type, implementation_class)
  invocation = "action()"
  normalized_block_type = block_type.gsub(/\b_(?:Nonnull|Nullable)\b/, "").gsub(/\s+/, " ").strip
  lookup = facade.kind == "+" ? "JobsBlockClassMethodIMP" : "JobsBlockInstanceMethodIMP"
  facade_dispatch = "((#{normalized_block_type} (*)(__typeof__(self), SEL))#{lookup}(#{implementation_class}.class, @selector(#{facade.facade})))" \
                    "(self, @selector(#{facade.facade}))"
  body = if facade.original_return == "void"
           "    #{block_type} action = #{facade_dispatch};\n" \
             "    if (action) #{invocation};\n"
         else
           "    #{block_type} action = #{facade_dispatch};\n" \
             "    return action ? #{invocation} : #{facade.fallback};\n"
         end
  "#{facade.kind}(#{facade.original_return})#{facade.selector}{\n#{body}}\n\n"
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: ensure_oc_legacy_selector_block_facades.rb [--apply] PATH..."
  parser.on("--apply", "Write fixed-selector wrappers and Jobs Block facades") { options[:apply] = true }
end.parse!

abort "At least one path is required" if ARGV.empty?

changed_files = 0
changed_methods = 0
files = source_files(ARGV)
owned_sources = files.to_h do |path|
  original = File.binread(path)
  utf8 = original.dup.force_encoding(Encoding::UTF_8)
  owned = utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, original)
  [path, owned ? original : nil]
end.compact
singleton_classes = owned_sources.each_with_object(Set.new) do |(_path, source), classes|
  next unless source.match?(/\)\s*(?:sharedManager|jobsSharedManager)\b/)

  source.scan(/@(?:interface|implementation)\s+([A-Za-z_]\w*)/) do |match|
    classes << match.first
  end
end
singleton_class_pattern = Regexp.union(singleton_classes.sort_by { |name| -name.length }) unless singleton_classes.empty?

owned_sources.each do |path, original|
  next if File.basename(path) == "MacroDef_Singleton.h"

  source = original.dup
  FACADES.each do |facade|
    if %w[sharedManager destroySingleton].include?(facade.selector)
      source.gsub!(/\bself\.\s*#{Regexp.escape(facade.selector)}\s*\(\s*\)/, "self.#{facade.facade}()")
      if singleton_class_pattern
        source.gsub!(/\b(#{singleton_class_pattern})\.\s*#{Regexp.escape(facade.selector)}\s*\(\s*\)/, "\\1.#{facade.facade}()")
      end
    elsif !FIXED_PROTOCOL_RECEIVER_SELECTORS.include?(facade.selector)
      source.gsub!(/\.\s*#{Regexp.escape(facade.selector)}\s*\(\s*\)/, ".#{facade.facade}()")
    end

    signature = /#{Regexp.escape(facade.kind)}\s*\(\s*(#{BLOCK_RETURN_PATTERN})\s*\)\s*#{Regexp.escape(facade.selector)}\s*([;{])/
    source.gsub!(signature) do
      matched_source = Regexp.last_match(0)
      match_offset = Regexp.last_match.begin(0)
      block_type = Regexp.last_match(1).strip
      terminator = Regexp.last_match(2)
      changed_methods += 1
      if terminator == ";"
          "#{facade.kind}(#{facade.original_return})#{facade.selector};\n" \
          "#{facade.kind}(#{block_type})#{facade.facade};"
      else
        implementation_class = implementation_class_at(source, match_offset)
        next matched_source unless implementation_class

        "#{wrapper(facade, block_type, implementation_class)}#{facade.kind}(#{block_type})#{facade.facade}{"
      end
    end
  end

  next if source == original

  File.binwrite(path, source) if options[:apply]
  changed_files += 1
  puts [options[:apply] ? "updated" : "would-update", path].join("\t")
end

warn "methods=#{changed_methods} files=#{changed_files} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
