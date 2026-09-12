#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"

PlanItem = Struct.new(
  :path, :kind, :class_name, :selector, :original_type, :block_type,
  keyword_init: true
)

JOBS_BLOCK_IMPORT = <<~'OBJC'

  #if __has_include(<JobsBlock/JobsBlock.h>)
  #import <JobsBlock/JobsBlock.h>
  #else
  #import "JobsBlock.h"
  #endif
OBJC

def facade_name(selector)
  "jobs#{selector[0].upcase}#{selector[1..]}"
end

def normalized_block_type(type)
  type.gsub(/\b_(?:Nonnull|Nullable)\b/, "").gsub(/\s+/, " ").strip
end

def fallback_value(type)
  normalized = type.gsub(/\b_(?:Nonnull|Nullable)\b/, "").strip
  return "Nil" if normalized == "Class"
  return "nil" if normalized.match?(/\*\s*\z/) || normalized.match?(/\b(?:id|instancetype)\b/)

  "(#{normalized}){0}"
end

def helper_name(kind)
  kind == "+" ? "JobsBlockClassMethodIMP" : "JobsBlockInstanceMethodIMP"
end

def method_pattern(item)
  /^[ \t]*#{Regexp.escape(item.kind)}[ \t]*\((#{Regexp.escape(item.block_type)}[^)]*)\)[ \t]*#{Regexp.escape(item.selector)}\b([^:{;]*)\{/m
end

def header_candidates(path, class_name)
  direct = path.sub(/\.(?:m|mm)\z/, ".h")
  return [direct] if File.file?(direct)

  directory = File.dirname(path)
  Dir.glob(File.join(directory, "**", "*.h")).select do |header|
    File.binread(header).include?("@interface #{class_name}")
  end
end

def update_header(source, item, availability)
  facade = facade_name(item.selector)
  return source if source.match?(/^[ \t]*#{Regexp.escape(item.kind)}[ \t]*\([^)]*\)[ \t]*#{Regexp.escape(facade)}\b/m)

  explicit = /^[ \t]*#{Regexp.escape(item.kind)}[ \t]*\(#{Regexp.escape(item.block_type)}[^)]*\)[ \t]*#{Regexp.escape(item.selector)}\b([^;]*);/m
  if (match = source.match(explicit))
    suffix = match[1].to_s.strip
    getter = "#{item.kind}(#{item.original_type})#{item.selector}#{suffix.empty? ? '' : " #{suffix}"};"
    block = "#{item.kind}(#{item.block_type})#{facade}#{suffix.empty? ? '' : " #{suffix}"};"
    source[match.begin(0)...match.end(0)] = "#{getter}\n#{block}"
    return source
  end

  interface = source.match(/@interface\s+#{Regexp.escape(item.class_name)}\b[^\n]*(.*?)@end/m)
  return source unless interface

  insertion = interface.end(0) - "@end".bytesize
  declaration = "#{item.kind}(#{item.block_type})#{facade}#{availability.empty? ? '' : " #{availability}"};\n\n"
  source.insert(insertion, declaration)
end

def ensure_jobs_block_import(source)
  return source if source.include?("<JobsBlock/JobsBlock.h>") ||
                   source.match?(/^#import\s+["<]JobsBlock\.h[">]/)

  first_import = source.match(/^#import[^\r\n]*(?:\r?\n)/)
  return source unless first_import

  source.insert(first_import.end(0), JOBS_BLOCK_IMPORT)
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: restore_oc_fixed_property_getter_facades.rb [--apply] PLAN.tsv"
  parser.on("--apply", "Restore property getter ABI and add jobsXxx Block facades") { options[:apply] = true }
end.parse!

abort "Exactly one plan TSV is required" unless ARGV.length == 1

items = File.readlines(ARGV[0], chomp: true).filter_map do |line|
  next if line.strip.empty? || line.start_with?("#")
  path, kind, class_name, selector, original_type, block_type = line.split("\t")
  next unless block_type

  PlanItem.new(
    path: File.expand_path(path),
    kind: kind,
    class_name: class_name,
    selector: selector,
    original_type: original_type,
    block_type: block_type
  )
end

source_updates = 0
header_updates = 0
items.each do |item|
  original = File.binread(item.path)
  next unless JobsOCOwnership.jobs_owned_file?(item.path, original)

  source = original.dup
  match = source.match(method_pattern(item))
  next unless match

  facade = facade_name(item.selector)
  availability = match[2].to_s.strip
  block_type = normalized_block_type(item.block_type)
  dispatch = "((#{block_type} (*)(__typeof__(self), SEL))#{helper_name(item.kind)}(#{item.class_name}.class, @selector(#{facade})))" \
             "(self, @selector(#{facade}))"
  wrapper_body = if item.original_type.gsub(/\s+/, "") == "void"
                   "    #{item.block_type} action = #{dispatch};\n" \
                     "    if (action) action();\n"
                 else
                   "    #{item.block_type} action = #{dispatch};\n" \
                     "    return action ? action() : #{fallback_value(item.original_type)};\n"
                 end
  wrapper = "#{item.kind}(#{item.original_type})#{item.selector}#{availability.empty? ? '' : " #{availability}"}{\n" \
            "#{wrapper_body}" \
            "}\n\n"
  facade_signature = match[0].sub(/#{Regexp.escape(item.selector)}\b/, facade)
  source[match.begin(0)...match.end(0)] = "#{wrapper}#{facade_signature}"

  if options[:apply]
    File.binwrite(item.path, source)
  end
  source_updates += 1
  puts [options[:apply] ? "updated" : "would-update", item.path, item.selector, facade].join("\t")

  header_candidates(item.path, item.class_name).each do |header|
    header_original = File.binread(header)
    next unless JobsOCOwnership.jobs_owned_file?(header, header_original)

    header_source = update_header(header_original.dup, item, availability)
    header_source = ensure_jobs_block_import(header_source) unless header_source == header_original
    next if header_source == header_original

    File.binwrite(header, header_source) if options[:apply]
    header_updates += 1
    puts [options[:apply] ? "updated-header" : "would-update-header", header, item.selector, facade].join("\t")
    break
  end
end

warn "methods=#{source_updates} headers=#{header_updates} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
