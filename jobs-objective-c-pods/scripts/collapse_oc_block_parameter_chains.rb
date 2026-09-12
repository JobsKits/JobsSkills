#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
require_relative "jobs_oc_ownership"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze
EXCLUDED_FRAGMENTS = %w[Manual_Add_ThirdParty].freeze
EXCLUDED_PARAMETER_TYPES = %w[
  MASConstraintMaker MASViewConstraint NSLayoutConstraint
].freeze
TERMINAL_CHAIN_SELECTORS = %w[
  actionRetIDByGestureRecognizerBlock
  actionObjBlock
  byAdd
  byData
  jobsRichViewByModel
  onSpinningStateChanged
].freeze

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) ||
      EXCLUDED_FRAGMENTS.any? { |fragment| component.include?(fragment) }
  end
end

def source_files(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{m,mm}"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end

def mask_non_code(source)
  bytes = source.b
  masked = bytes.dup
  index = 0
  state = :code
  while index < bytes.length
    current = bytes[index]
    following = index + 1 < bytes.length ? bytes[index + 1] : nil
    case state
    when :code
      if current == "/" && following == "/"
        masked[index, 2] = "  "; index += 2; state = :line_comment
      elsif current == "/" && following == "*"
        masked[index, 2] = "  "; index += 2; state = :block_comment
      elsif current == '"'
        masked.setbyte(index, 32); index += 1; state = :string
      elsif current == "'"
        masked.setbyte(index, 32); index += 1; state = :character
      else
        index += 1
      end
    when :line_comment
      if current == "\n"
        index += 1; state = :code
      else
        masked.setbyte(index, 32); index += 1
      end
    when :block_comment
      if current == "*" && following == "/"
        masked[index, 2] = "  "; index += 2; state = :code
      else
        masked.setbyte(index, 32) unless current == "\n"; index += 1
      end
    when :string, :character
      terminal = state == :string ? '"' : "'"
      if current == "\\"
        masked.setbyte(index, 32); index += 1
        if index < bytes.length
          masked.setbyte(index, 32) unless bytes[index] == "\n"
          index += 1
        end
      elsif current == terminal
        masked.setbyte(index, 32); index += 1; state = :code
      else
        masked.setbyte(index, 32) unless current == "\n"; index += 1
      end
    end
  end
  masked
end

def block_end(masked, opening_brace)
  depth = 1
  cursor = opening_brace + 1
  while cursor < masked.bytesize && depth.positive?
    byte = masked.getbyte(cursor)
    depth += 1 if byte == 123
    depth -= 1 if byte == 125
    cursor += 1
  end
  depth.zero? ? cursor : nil
end

def chain_statements(masked, body_start, body_end, parameters)
  statements = []
  segment_start = body_start
  segment_index = 0
  brace_depth = 0
  parenthesis_depth = 0
  bracket_depth = 0
  cursor = body_start

  while cursor < body_end
    byte = masked.getbyte(cursor)
    case byte
    when 123 # {
      brace_depth += 1
    when 125 # }
      brace_depth -= 1
      if brace_depth.zero? && parenthesis_depth.zero? && bracket_depth.zero?
        segment_start = cursor + 1
        segment_index += 1
      end
    when 40 # (
      parenthesis_depth += 1
    when 41 # )
      parenthesis_depth -= 1
    when 91 # [
      bracket_depth += 1
    when 93 # ]
      bracket_depth -= 1
    when 59 # ;
      if brace_depth.zero? && parenthesis_depth.zero? && bracket_depth.zero?
        fragment = masked.byteslice(segment_start..cursor)
        parameters.each do |parameter|
          match = fragment.match(/(?:\A|\n)[ \t]*(#{Regexp.escape(parameter)})\s*(\.[\s\S]*);\s*\z/)
          next unless match
          prefix = fragment.byteslice(0...match.begin(1))
          prefix_without_jobs_lifetime = prefix.gsub(/@jobs_(?:weak|strong)ify\s*\([^)]*\)/, "")
          next unless prefix_without_jobs_lifetime.strip.empty?
          next unless match[2].match?(/\A\s*\.[A-Za-z_]\w*\s*\(/)
          selectors = match[2].scan(/\.([A-Za-z_]\w*)\s*\(/).flatten
          next if selectors.any? { |selector| TERMINAL_CHAIN_SELECTORS.include?(selector) }

          statements << {
            parameter: parameter,
            segment: segment_index,
            receiver_start: segment_start + match.begin(1),
            receiver_end: segment_start + match.end(1),
            semicolon: cursor
          }
          break
        end
        segment_start = cursor + 1
        segment_index += 1
      end
    end
    cursor += 1
  end
  statements
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: collapse_oc_block_parameter_chains.rb [--apply] PATH..."
  parser.on("--apply", "Collapse adjacent single-line DSL calls into one receiver chain") do
    options[:apply] = true
  end
end.parse!

abort "At least one path is required" if ARGV.empty?

changed_files = 0
collapsed_runs = 0
collapsed_calls = 0

source_files(ARGV).each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  masked = mask_non_code(source)
  replacements = []
  search_offset = 0
  while (block = masked.match(/\^\s*\(([^)]*)\)\s*\{/n, search_offset))
    parameters = block[1].split(",").filter_map do |signature|
      next if EXCLUDED_PARAMETER_TYPES.any? { |type| signature.include?(type) }
      signature.scan(/[A-Za-z_]\w*/).last
    end

    opening_brace = block.end(0) - 1
    ending = block_end(masked, opening_brace)
    break unless ending

    statements = chain_statements(masked, opening_brace + 1, ending - 1, parameters)
    runs = []
    statements.each do |statement|
      if runs.empty? ||
         statement[:parameter] != runs.last.last[:parameter] ||
         statement[:segment] != runs.last.last[:segment] + 1
        runs << [statement]
      else
        runs.last << statement
      end
    end

    runs.select { |run| run.length > 1 }.each do |run|
      line = source.byteslice(0...run.first[:receiver_start]).count("\n") + 1
      replacements << { run: run, line: line, count: run.length }
    end
    search_offset = ending
  end

  next if replacements.empty?

  collapsed_runs += replacements.length
  collapsed_calls += replacements.sum { |entry| entry[:count] }
  replacements.sort_by { |entry| entry[:line] }.each do |entry|
    puts [options[:apply] ? "collapse" : "would-collapse", path, entry[:line], entry[:count]].join("\t")
  end
  if options[:apply]
    updated = source.dup
    edits = replacements.flat_map do |entry|
      run = entry[:run]
      run[0...-1].map { |statement| [statement[:semicolon], statement[:semicolon] + 1, ""] } +
        run.drop(1).map { |statement| [statement[:receiver_start], statement[:receiver_end], ""] }
    end
    edits.sort_by(&:first).reverse_each do |start_offset, end_offset, rendered|
      updated[start_offset...end_offset] = rendered
    end
    File.binwrite(path, updated)
  end
  changed_files += 1
end

warn "collapsed_runs=#{collapsed_runs} collapsed_calls=#{collapsed_calls} files=#{changed_files} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
exit 0
