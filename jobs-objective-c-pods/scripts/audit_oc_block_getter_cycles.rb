#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "pathname"
require "set"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

REVIEWED_CONDITIONAL_CYCLES = [
  {
    file: "JobsLabelScrollController.m",
    selectors: Set.new(%w[createAndStartTimer rebuild tick])
  }
].freeze

MethodInfo = Struct.new(
  :selector, :return_type, :body_open, :body_close, :line,
  keyword_init: true
)

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

def mask_non_code(source)
  masked = source.b.dup
  index = 0
  state = :code
  while index < source.bytesize
    current = source.getbyte(index)
    following = index + 1 < source.bytesize ? source.getbyte(index + 1) : nil
    case state
    when :code
      if current == 47 && following == 47
        masked[index, 2] = "  "; index += 2; state = :line_comment
      elsif current == 47 && following == 42
        masked[index, 2] = "  "; index += 2; state = :block_comment
      elsif current == 34
        masked.setbyte(index, 32); index += 1; state = :string
      elsif current == 39
        masked.setbyte(index, 32); index += 1; state = :character
      else
        index += 1
      end
    when :line_comment
      if current == 10
        index += 1; state = :code
      else
        masked.setbyte(index, 32); index += 1
      end
    when :block_comment
      if current == 42 && following == 47
        masked[index, 2] = "  "; index += 2; state = :code
      else
        masked.setbyte(index, 32) unless current == 10; index += 1
      end
    when :string, :character
      terminal = state == :string ? 34 : 39
      if current == 92
        masked.setbyte(index, 32); index += 1
        if index < source.bytesize
          masked.setbyte(index, 32) unless source.getbyte(index) == 10; index += 1
        end
      elsif current == terminal
        masked.setbyte(index, 32); index += 1; state = :code
      else
        masked.setbyte(index, 32) unless current == 10; index += 1
      end
    end
  end
  masked
end

def matching_delimiter(source, opening, open_byte, close_byte)
  depth = 0
  cursor = opening
  while cursor < source.bytesize
    byte = source.getbyte(cursor)
    depth += 1 if byte == open_byte
    if byte == close_byte
      depth -= 1
      return cursor if depth.zero?
    end
    cursor += 1
  end
  nil
end

def signature_terminator(source, offset)
  parentheses = 0
  brackets = 0
  cursor = offset
  while cursor < source.bytesize
    case source.getbyte(cursor)
    when 40 then parentheses += 1
    when 41 then parentheses -= 1
    when 91 then brackets += 1
    when 93 then brackets -= 1
    when 59, 123
      return cursor if parentheses.zero? && brackets.zero?
    end
    cursor += 1
  end
  nil
end

def method_selector(signature)
  labels = signature.scan(/\b([A-Za-z_]\w*)\s*:/).flatten
  return "#{labels.join(':')}:" unless labels.empty?

  signature[/\A([A-Za-z_]\w*)\b/, 1]
end

def methods(source, masked)
  result = []
  offset = 0
  while (match = masked.match(/^[ \t]*[+-][ \t]*\(/m, offset))
    opening = masked.index("(", match.begin(0))
    closing = matching_delimiter(masked, opening, 40, 41)
    break unless closing

    terminator = signature_terminator(masked, closing + 1)
    break unless terminator

    if masked.getbyte(terminator) == 123
      body_close = matching_delimiter(masked, terminator, 123, 125)
      break unless body_close

      signature = source[(closing + 1)...terminator].strip.gsub(/\s+/, " ")
      result << MethodInfo.new(
        selector: method_selector(signature),
        return_type: source[(opening + 1)...closing].strip,
        body_open: terminator,
        body_close: body_close,
        line: source.byteslice(0, match.begin(0)).count("\n") + 1
      )
      offset = body_close + 1
    else
      offset = terminator + 1
    end
  end
  result
end

def block_type?(type)
  type.match?(/\b(?:Jobs|jobs)[A-Za-z_]\w*Blocks?\b/) || type.match?(/\b\w+_block_t\b/)
end

def strongly_connected_components(graph)
  index = 0
  stack = []
  indices = {}
  low_links = {}
  on_stack = Set.new
  components = []

  visit = lambda do |node|
    indices[node] = index
    low_links[node] = index
    index += 1
    stack << node
    on_stack << node

    graph.fetch(node, []).each do |target|
      unless indices.key?(target)
        visit.call(target)
        low_links[node] = [low_links[node], low_links[target]].min
      else
        low_links[node] = [low_links[node], indices[target]].min if on_stack.include?(target)
      end
    end

    return unless low_links[node] == indices[node]

    component = []
    loop do
      target = stack.pop
      on_stack.delete(target)
      component << target
      break if target == node
    end
    components << component
  end

  graph.each_key { |node| visit.call(node) unless indices.key?(node) }
  components
end

abort "Usage: audit_oc_block_getter_cycles.rb PATH..." if ARGV.empty?

cycle_count = 0
file_count = 0
source_files(ARGV).each do |path|
  original = File.binread(path)
  next unless original.dup.force_encoding(Encoding::UTF_8).valid_encoding?
  next unless JobsOCOwnership.jobs_owned_file?(path, original)

  masked = mask_non_code(original)
  block_methods = methods(original, masked).select do |method|
    method.selector && !method.selector.include?(":") && block_type?(method.return_type)
  end
  next if block_methods.empty?

  selectors = block_methods.map(&:selector).to_set
  lines = block_methods.to_h { |method| [method.selector, method.line] }
  graph = block_methods.to_h do |method|
    body = masked[(method.body_open + 1)...method.body_close]
    targets = []
    body.scan(/\bself\s*\.\s*([A-Za-z_]\w*)\s*\(/) { |capture| targets << capture.first }
    body.scan(/\[\s*self\s+([A-Za-z_]\w*)\s*\]\s*\(/) { |capture| targets << capture.first }
    body.scan(/\breturn\s+self\s*\.\s*([A-Za-z_]\w*)\s*;/) { |capture| targets << capture.first }
    [method.selector, targets.select { |target| selectors.include?(target) }.uniq]
  end

  cycles = strongly_connected_components(graph).select do |component|
    component.length > 1
  end.reject do |component|
    REVIEWED_CONDITIONAL_CYCLES.any? do |reviewed|
      File.basename(path) == reviewed[:file] && component.to_set == reviewed[:selectors]
    end
  end
  next if cycles.empty?

  file_count += 1
  cycles.each do |component|
    cycle_count += 1
    detail = component.sort.map { |selector| "#{selector}:#{lines[selector]}" }.join(" -> ")
    puts ["block-getter-cycle", path, detail].join("\t")
  end
end

warn "files=#{file_count} cycles=#{cycle_count}"
exit(cycle_count.positive? ? 2 : 0)
