#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "set"
require_relative "jobs_swift_ownership"

EXCLUDED_COMPONENTS = %w[
  .git
  .build
  .dart_tool
  Pods
  ManualBySwiftPods@Pods
  build
  DerivedData
  generated
].freeze
EXCLUDED_COMPONENT_FRAGMENTS = %w[
  GeneratedPluginRegistrant
  Il2CppOutputProject
].freeze
LOW_LEVEL_DSL_COMPONENTS = %w[
  JobsByUIKit@Pods
  JobsSwiftDSL@Pods
].freeze
BOOL_PROPERTY_ALIASES = {
  "isEnabled" => "byEnabled",
  "isHidden" => "byHidden",
  "isHighlighted" => "byHighlighted",
  "isOn" => "byOn",
  "isPagingEnabled" => "byPagingEnabled",
  "isPaused" => "byPaused",
  "isScrollEnabled" => "byScrollEnabled",
  "isSecureTextEntry" => "bySecureTextEntry",
  "isSelected" => "bySelected",
  "isUserInteractionEnabled" => "byUserInteractionEnabled"
}.freeze

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) ||
      EXCLUDED_COMPONENT_FRAGMENTS.any? { |fragment| component.include?(fragment) }
  end
end

def low_level_dsl?(path)
  path.each_filename.any? { |component| LOW_LEVEL_DSL_COMPONENTS.include?(component) }
end

def source_files(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.swift"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end

def mask_comments_and_literals(source)
  source = source.b
  masked = source.dup
  index = 0
  state = :code
  multiline_hashes = 0

  while index < source.length
    current = source.getbyte(index)
    following = index + 1 < source.length ? source.getbyte(index + 1) : nil

    case state
    when :code
      if current == 47 && following == 47
        masked.setbyte(index, 32)
        masked.setbyte(index + 1, 32)
        index += 2
        state = :line_comment
      elsif current == 47 && following == 42
        masked.setbyte(index, 32)
        masked.setbyte(index + 1, 32)
        index += 2
        state = :block_comment
      elsif source.byteslice(index, 3) == '"""'
        3.times { |offset| masked.setbyte(index + offset, 32) }
        index += 3
        state = :multiline_string
        multiline_hashes = 0
      elsif current == 34
        masked.setbyte(index, 32)
        index += 1
        state = :string
      else
        index += 1
      end
    when :line_comment
      if current == 10
        index += 1
        state = :code
      else
        masked.setbyte(index, 32)
        index += 1
      end
    when :block_comment
      if current == 42 && following == 47
        masked.setbyte(index, 32)
        masked.setbyte(index + 1, 32)
        index += 2
        state = :code
      else
        masked.setbyte(index, 32) unless current == 10
        index += 1
      end
    when :string
      if current == 92
        masked.setbyte(index, 32)
        index += 1
        if index < source.length
          masked.setbyte(index, 32) unless source.getbyte(index) == 10
          index += 1
        end
      elsif current == 34
        masked.setbyte(index, 32)
        index += 1
        state = :code
      else
        masked.setbyte(index, 32) unless current == 10
        index += 1
      end
    when :multiline_string
      if source.byteslice(index, 3 + multiline_hashes) == ('"""' + ("#" * multiline_hashes))
        (3 + multiline_hashes).times { |offset| masked.setbyte(index + offset, 32) }
        index += 3 + multiline_hashes
        state = :code
      else
        masked.setbyte(index, 32) unless current == 10
        index += 1
      end
    end
  end

  masked.force_encoding(Encoding::UTF_8)
end

def dsl_methods(roots)
  methods = Set.new
  roots.each do |root|
    expanded = File.expand_path(root)
    candidates = if File.basename(expanded) == "JobsSwiftDSL@Pods"
                   [expanded]
                 else
                   Dir.glob(File.join(expanded, "**", "JobsSwiftDSL@Pods"))
                 end
    candidates.each do |candidate|
      Dir.glob(File.join(candidate, "**", "*.swift")).each do |path|
        source = File.binread(path).force_encoding(Encoding::UTF_8)
        next unless source.valid_encoding?

        source.scan(/\bfunc\s+(by[A-Z][A-Za-z0-9_]*)\s*\(/) { |match| methods << match.first }
      end
    end
  end
  methods
end

def candidate_method(property)
  BOOL_PROPERTY_ALIASES.fetch(property) do
    "by#{property.sub(/\A./) { |letter| letter.upcase }}"
  end
end

roots = ARGV.empty? ? ["."] : ARGV
files = source_files(roots)
methods = dsl_methods(roots)
bare_assignments = []
repeat_groups = []

files.each do |path|
  source = File.binread(path).force_encoding(Encoding::UTF_8)
  next unless source.valid_encoding?
  next unless JobsSwiftOwnership.jobs_owned_file?(path, source)

  masked = mask_comments_and_literals(source)
  stack = [{ starts: Hash.new { |hash, key| hash[key] = [] } }]

  masked.each_line.with_index(1) do |line, line_number|
    stripped = line.strip
    receiver_match = stripped.match(/\A((?:self\.)?[a-z_][A-Za-z0-9_]*(?:(?:\?\.|\.)[A-Za-z_][A-Za-z0-9_]*)*)(?:\?\.|\.)([A-Za-z_][A-Za-z0-9_]*)/)
    if receiver_match
      receiver = receiver_match[1]
      root_receiver = receiver.sub(/\Aself\./, "").split(/[?.]/).first
      stack.last[:starts][root_receiver] << {
        line: line_number,
        receiver: receiver,
        dsl: stripped.match?(/\.(?:by|jobs)[A-Z_a-z0-9]*\s*\(/),
        assignment: stripped.match?(/\.[A-Za-z_][A-Za-z0-9_]*\s*=\s*(?!=)/)
      }
    end

    unless low_level_dsl?(Pathname(path))
      assignment = stripped.match(/\A((?:self\.)?[a-z_][A-Za-z0-9_]*(?:(?:\?\.|\.)[A-Za-z_][A-Za-z0-9_]*)*)\.([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?!=)/)
      if assignment
        receiver = assignment[1]
        property = assignment[2]
        method = candidate_method(property)
        if methods.include?(method)
          bare_assignments << {
            path: path,
            line: line_number,
            receiver: receiver,
            property: property,
            method: method
          }
        end
      end
    end

    line.each_char do |character|
      case character
      when "{"
        stack << { starts: Hash.new { |hash, key| hash[key] = [] } }
      when "}"
        next if stack.length == 1

        block = stack.pop
        block[:starts].each do |receiver, starts|
          next if starts.length < 2
          next unless starts.any? { |start| start[:dsl] || start[:assignment] }

          clustered = starts.chunk_while { |left, right| right[:line] - left[:line] <= 20 }.to_a
          clustered.each do |cluster|
            next if cluster.length < 2

            repeat_groups << {
              path: path,
              receiver: receiver,
              lines: cluster.map { |start| start[:line] },
              receivers: cluster.map { |start| start[:receiver] }.uniq
            }
          end
        end
      end
    end
  end
end

bare_assignments.each do |issue|
  puts format(
    "%<path>s:%<line>d: bare assignment %<receiver>s.%<property>s -> %<method>s(...) exists",
    **issue
  )
end

repeat_groups.each do |issue|
  puts format(
    "%<path>s:%<line>d: receiver %<receiver>s restarts at lines %<lines>s (%<receivers>s)",
    path: issue[:path],
    line: issue[:lines].first,
    receiver: issue[:receiver],
    lines: issue[:lines].join(","),
    receivers: issue[:receivers].join(" | ")
  )
end

puts format(
  "bare_assignments=%<bare>d repeat_groups=%<repeats>d issue_files=%<issue_files>d scanned=%<scanned>d dsl_methods=%<methods>d",
  bare: bare_assignments.length,
  repeats: repeat_groups.length,
  issue_files: (bare_assignments.map { |issue| issue[:path] } + repeat_groups.map { |issue| issue[:path] }).uniq.length,
  scanned: files.length,
  methods: methods.length
)

exit(bare_assignments.empty? && repeat_groups.empty? ? 0 : 2)
