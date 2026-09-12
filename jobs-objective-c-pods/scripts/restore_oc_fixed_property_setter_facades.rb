#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"

PlanItem = Struct.new(
  :path, :kind, :class_name, :selector, :parameter_type, :parameter_name, :block_type,
  keyword_init: true
)

def facade_name(selector)
  "jobs#{selector[0].upcase}#{selector[1..]}"
end

def normalized_block_type(type)
  type.gsub(/\b_(?:Nonnull|Nullable)\b/, "").gsub(/\s+/, " ").strip
end

def helper_name(kind)
  kind == "+" ? "JobsBlockClassMethodIMP" : "JobsBlockInstanceMethodIMP"
end

def header_candidates(path, class_name)
  direct = path.sub(/\.(?:m|mm)\z/, ".h")
  candidates = [direct]
  directory = File.dirname(path)
  candidates.concat(Dir.glob(File.join(directory, "*.h")))
  candidates.concat(Dir.glob(File.join(directory, "**", "*.h")))
  candidates.uniq.select do |header|
    File.file?(header) && File.binread(header).include?("@interface #{class_name}")
  end
end

def update_header(source, item)
  facade = facade_name(item.selector)
  return source if source.match?(/^[ \t]*#{Regexp.escape(item.kind)}[ \t]*\([^)]*\)[ \t]*#{Regexp.escape(facade)}\b/m)

  explicit = /^[ \t]*#{Regexp.escape(item.kind)}[ \t]*\(#{Regexp.escape(item.block_type)}[^)]*\)[ \t]*#{Regexp.escape(item.selector)}\b([^;]*);/m
  match = source.match(explicit)
  return source unless match

  suffix = match[1].to_s.strip
  setter = "#{item.kind}(void)#{item.selector}:(#{item.parameter_type})#{item.parameter_name};"
  block = "#{item.kind}(#{item.block_type} _Nonnull)#{facade}#{suffix.empty? ? '' : " #{suffix}"};"
  source[match.begin(0)...match.end(0)] = "#{setter}\n#{block}"
  source
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: restore_oc_fixed_property_setter_facades.rb [--apply] PLAN.tsv"
  parser.on("--apply", "Restore property setter ABI and add jobsSetXxx Block facades") { options[:apply] = true }
end.parse!

abort "Exactly one plan TSV is required" unless ARGV.length == 1

items = File.readlines(ARGV[0], chomp: true).filter_map do |line|
  next if line.strip.empty? || line.start_with?("#")

  path, kind, class_name, selector, parameter_type, parameter_name, block_type = line.split("\t")
  next unless block_type

  PlanItem.new(
    path: File.expand_path(path),
    kind: kind,
    class_name: class_name,
    selector: selector,
    parameter_type: parameter_type,
    parameter_name: parameter_name,
    block_type: block_type
  )
end

source_updates = 0
header_updates = 0
items.each do |item|
  original = File.binread(item.path)
  next unless JobsOCOwnership.jobs_owned_file?(item.path, original)

  facade = facade_name(item.selector)
  pattern = /^[ \t]*#{Regexp.escape(item.kind)}[ \t]*\((#{Regexp.escape(item.block_type)}[^)]*)\)[ \t]*#{Regexp.escape(item.selector)}\b([^:{;]*)\{/m
  match = original.match(pattern)
  next unless match

  source = original.dup
  block_type = normalized_block_type(item.block_type)
  dispatch = "((#{block_type} (*)(__typeof__(self), SEL))#{helper_name(item.kind)}(#{item.class_name}.class, @selector(#{facade})))" \
             "(self, @selector(#{facade}))"
  wrapper = "#{item.kind}(void)#{item.selector}:(#{item.parameter_type})#{item.parameter_name}{\n" \
            "    #{block_type} action = #{dispatch};\n" \
            "    if (action) action(#{item.parameter_name});\n" \
            "}\n\n"
  existing_wrapper = /^[ \t]*#{Regexp.escape(item.kind)}[ \t]*\(void\)[ \t]*#{Regexp.escape(item.selector)}[ \t]*:[ \t]*\([^)]*\)[ \t]*[A-Za-z_]\w*[ \t]*\{.*?^[ \t]*\}[ \t]*(?:\r?\n)*/m
  if (wrapper_match = source.match(existing_wrapper))
    source[wrapper_match.begin(0)...wrapper_match.end(0)] = wrapper
    match = source.match(pattern)
    next unless match
    facade_signature = match[0].sub(/#{Regexp.escape(item.selector)}\b/, facade)
    source[match.begin(0)...match.end(0)] = facade_signature
  else
    facade_signature = match[0].sub(/#{Regexp.escape(item.selector)}\b/, facade)
    source[match.begin(0)...match.end(0)] = "#{wrapper}#{facade_signature}"
  end
  File.binwrite(item.path, source) if options[:apply]
  source_updates += 1
  puts [options[:apply] ? "updated" : "would-update", item.path, item.selector, facade].join("\t")

  header_candidates(item.path, item.class_name).each do |header|
    header_original = File.binread(header)
    next unless JobsOCOwnership.jobs_owned_file?(header, header_original)

    header_source = update_header(header_original.dup, item)
    next if header_source == header_original

    File.binwrite(header, header_source) if options[:apply]
    header_updates += 1
    puts [options[:apply] ? "updated-header" : "would-update-header", header, item.selector, facade].join("\t")
    break
  end
end

warn "methods=#{source_updates} headers=#{header_updates} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
