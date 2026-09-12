#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "optparse"
require "pathname"
require_relative "jobs_oc_ownership"

EXCLUDED_COMPONENTS = %w[.git Pods ManualByOCPods@Pods PodsManual build DerivedData].freeze

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

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: ensure_oc_property_dsl_setter_declarations.rb [--apply] PATH..."
  parser.on("--apply", "Insert local setter declarations used by generated owner DSL kernels") { options[:apply] = true }
end.parse!
abort "At least one source PATH is required" if ARGV.empty?

def method_parameter(argument)
  block = argument.match(/\A(.+?)\(\s*\^\s*(?:_Nullable\s+)?data\s*\)\s*\((.*)\)\s*\z/m)
  return "(#{block[1].strip} (^ _Nullable)(#{block[2].strip}))data" if block
  "(#{argument.sub(/\s+data\z/, '')})data"
end

changed = 0
declaration_count = 0
source_files(ARGV).each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  declarations_by_owner = Hash.new { |hash, owner| hash[owner] = [] }
  source.scan(%r{// JOBS_PROPERTY_DSL_IMPLEMENTATION_AUTOGEN_BEGIN ([A-Za-z_]\w*)\n(.*?)// JOBS_PROPERTY_DSL_IMPLEMENTATION_AUTOGEN_END \1}m) do |owner, section|
    argument = nil
    method_sign = "-"
    section.lines.each do |line|
      stripped = line.strip
      if (method = stripped.match(/\A([+-])\([^)]*Block[^)]*\)[A-Za-z_]\w*\{/))
        method_sign = method[1]
      elsif (stripped.start_with?("return ^__kindof ") || stripped.start_with?("return ^Class ")) && stripped.end_with?("){")
        opening_token = stripped.start_with?("return ^Class ") ? "Class _Nullable(" : "* _Nullable("
        opening = stripped.index(opening_token)
        closing = stripped.rindex("){")
        argument = stripped[(opening + opening_token.length)...closing] if opening && closing
      elsif argument && (match = stripped.match(/\A\[self (set[A-Za-z_]\w*):data\];\z/))
        declarations_by_owner[owner] << "#{method_sign}(void)#{match[1]}:#{method_parameter(argument)};"
        argument = nil
      end
    end
  end
  next if declarations_by_owner.empty?

  edits = []
  declarations_by_owner.each do |owner, lines|
    lines = lines.sort.uniq
    next if lines.empty?
    begin_marker = "// JOBS_PROPERTY_DSL_SETTER_DECLARATION_AUTOGEN_BEGIN #{owner}"
    end_marker = "// JOBS_PROPERTY_DSL_SETTER_DECLARATION_AUTOGEN_END #{owner}"
    category = "JobsPropertyDSLSetterAutogen_#{Digest::SHA1.hexdigest(path)[0, 10]}"
    section = ([begin_marker, "@interface #{owner} (#{category})"] + lines + ["@end", end_marker, ""]).join("\n")
    pattern = /#{Regexp.escape(begin_marker)}(?=\r?\n).*?#{Regexp.escape(end_marker)}(?=\r?\n|\z)\r?\n?/m
    if source.match?(pattern)
      match = source.match(pattern)
      edits << [match.begin(0), match.end(0), section]
    else
      implementation = source.match(/^@implementation\s+#{Regexp.escape(owner)}(?:\s*\([^)]*\))?/)
      abort "Unable to locate @implementation #{owner} in #{path}" unless implementation
      edits << [implementation.begin(0), implementation.begin(0), "#{section}\n"]
    end
    declaration_count += lines.length
  end

  puts [options[:apply] ? "updated" : "candidate", path, declarations_by_owner.length].join("\t")
  next unless options[:apply]
  updated = source.dup
  edits.sort_by(&:first).reverse_each { |start_offset, end_offset, replacement| updated[start_offset...end_offset] = replacement }
  File.binwrite(path, updated)
  changed += 1
end

warn "declarations=#{declaration_count} files=#{changed} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
