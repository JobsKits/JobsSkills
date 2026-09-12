#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
EXCLUDED_COMPONENTS = %w[
  .git
  Pods
  ManualByOCPods@Pods
  PodsManual
  build
  DerivedData
].freeze
EXCLUDED_COMPONENT_FRAGMENTS = %w[
  Manual_Add_ThirdParty
].freeze
EXCLUDED_PARAMETER_TYPES = %w[
  MASConstraintMaker
  MASViewConstraint
  NSLayoutConstraint
].freeze
TERMINAL_CHAIN_SELECTORS = %w[
  actionRetIDByGestureRecognizerBlock
  actionObjBlock
  byAdd
  byData
  jobsRichViewByModel
  onSpinningStateChanged
].freeze

def mask_comments_and_literals(source)
  source = source.b
  masked = source.dup
  index = 0
  state = :code

  while index < source.length
    current = source[index]
    following = index + 1 < source.length ? source[index + 1] : nil

    case state
    when :code
      if current == "/" && following == "/"
        masked.setbyte(index, 32)
        masked.setbyte(index + 1, 32)
        index += 2
        state = :line_comment
      elsif current == "/" && following == "*"
        masked.setbyte(index, 32)
        masked.setbyte(index + 1, 32)
        index += 2
        state = :block_comment
      elsif current == '"'
        masked.setbyte(index, 32)
        index += 1
        state = :string
      elsif current == "'"
        masked.setbyte(index, 32)
        index += 1
        state = :character
      else
        index += 1
      end
    when :line_comment
      if current == "\n"
        index += 1
        state = :code
      else
        masked.setbyte(index, 32)
        index += 1
      end
    when :block_comment
      if current == "*" && following == "/"
        masked.setbyte(index, 32)
        masked.setbyte(index + 1, 32)
        index += 2
        state = :code
      else
        masked.setbyte(index, 32) unless current == "\n"
        index += 1
      end
    when :string, :character
      terminal = state == :string ? '"' : "'"
      if current == "\\"
        masked.setbyte(index, 32)
        index += 1
        if index < source.length
          masked.setbyte(index, 32) unless source[index] == "\n"
          index += 1
        end
      elsif current == terminal
        masked.setbyte(index, 32)
        index += 1
        state = :code
      else
        masked.setbyte(index, 32) unless current == "\n"
        index += 1
      end
    end
  end

  masked
end


def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) ||
      EXCLUDED_COMPONENT_FRAGMENTS.any? { |fragment| component.include?(fragment) }
  end
end

def source_files(roots)
  roots.flat_map do |root|
    root = File.expand_path(root)
    if File.file?(root)
      [root]
    else
      Dir.glob(File.join(root, "**", "*.{m,mm}"))
    end
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
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

def chain_statements(source, masked, body_start, body_end, parameters)
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
    when 123
      brace_depth += 1
    when 125
      brace_depth -= 1
      if brace_depth.zero? && parenthesis_depth.zero? && bracket_depth.zero?
        segment_start = cursor + 1
        segment_index += 1
      end
    when 40
      parenthesis_depth += 1
    when 41
      parenthesis_depth -= 1
    when 91
      bracket_depth += 1
    when 93
      bracket_depth -= 1
    when 59
      if brace_depth.zero? && parenthesis_depth.zero? && bracket_depth.zero?
        fragment = masked.byteslice(segment_start..cursor)
        parameters.each do |parameter, signature|
          match = fragment.match(/(?:\A|\n)[ \t]*(#{Regexp.escape(parameter)})\s*(\.[\s\S]*);\s*\z/)
          next unless match
          prefix = fragment.byteslice(0...match.begin(1))
          prefix_without_jobs_lifetime = prefix.gsub(/@jobs_(?:weak|strong)ify\s*\([^)]*\)/, "")
          next unless prefix_without_jobs_lifetime.strip.empty?
          next unless match[2].match?(/\A\s*\.[A-Za-z_]\w*\s*\(/)
          selectors = match[2].scan(/\.([A-Za-z_]\w*)\s*\(/).flatten
          next if selectors.any? { |selector| TERMINAL_CHAIN_SELECTORS.include?(selector) }

          receiver_start = segment_start + match.begin(1)
          statements << {
            parameter: parameter,
            signature: signature,
            segment: segment_index,
            line: source.byteslice(0...receiver_start).count("\n") + 1
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

require "pathname"

roots = ARGV.empty? ? ["."] : ARGV
issues = []
files = source_files(roots)

files.each do |path|
  utf8_source = File.binread(path).force_encoding(Encoding::UTF_8)
  next unless utf8_source.valid_encoding?
  next unless JobsOCOwnership.jobs_owned_file?(path, utf8_source)

  source = utf8_source.b
  masked = mask_comments_and_literals(source)
  offset = 0

  while (match = masked.match(/\^\s*\(([^)]*)\)\s*\{/n, offset))
    parameters = match[1].split(",").filter_map do |parameter|
      next if EXCLUDED_PARAMETER_TYPES.any? { |type| parameter.include?(type) }

      name = parameter.scan(/[A-Za-z_]\w*/).last
      [name, parameter]
    end
    opening_brace = match.end(0) - 1
    ending = block_end(masked, opening_brace)
    break unless ending

    statements = chain_statements(source, masked, opening_brace + 1, ending - 1, parameters)
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
      issues << {
        path: path,
        block_line: source.byteslice(0...opening_brace).count("\n") + 1,
        parameter: run.first[:parameter],
        signature: run.first[:signature].strip,
        count: run.length - 1,
        lines: run.map { |statement| statement[:line] }
      }
    end

    offset = ending
  end
end

issues.each do |issue|
  puts format(
    "%<path>s:%<block_line>d: %<parameter>s repeats in %<count>d adjacent chain group(s) at %<lines>s",
    **issue.merge(lines: issue[:lines].join(","))
  )
end

puts format(
  "issues=%<issues>d files=%<issue_files>d scanned=%<scanned>d",
  issues: issues.length,
  issue_files: issues.map { |issue| issue[:path] }.uniq.length,
  scanned: files.length
)

exit(issues.empty? ? 0 : 2)
