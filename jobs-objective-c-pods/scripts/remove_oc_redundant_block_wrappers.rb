#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"
require "set"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze
OBJC_METHOD_FAMILIES = /\A(?:init|new|alloc|copy|mutableCopy)(?:\z|[A-Z_:])/.freeze
FIXED_SELECTORS = Set.new(%w[
  .cxx_destruct dealloc load initialize sharedManager destroySingleton
  class superclass hash description debugDescription
  forwardingTargetForSelector: forwardInvocation: methodSignatureForSelector:
  respondsToSelector: conformsToProtocol: isEqual: isKindOfClass: isMemberOfClass:
  doesNotRecognizeSelector: resolveClassMethod: resolveInstanceMethod:
]).freeze
SYSTEM_CALLBACK_PATTERNS = [
  /\Aapplication:/, /\Ascene:/, /\AURLSession:/,
  /\AcollectionView:/, /\AtableView:/, /\AscrollView/,
  /\AsearchBar/, /\AtextView/, /\AtextField/,
  /\AnavigationController:/, /\AgestureRecognizer/,
  /\AviewDid/, /\AviewWill/, /\AviewSafeAreaInsetsDidChange\z/,
  /\AloadView\z/, /\AlayoutSubviews\z/, /\AprepareForReuse\z/,
  /\AobserveValueForKeyPath:/, /\AencodeWithCoder:/,
  /\Atouches(?:Began|Cancelled|Ended|Moved):/,
  /\AtextFieldShould/, /\AtransitionDuration:/,
  /\AtraitCollectionDidChange:/,
  /\A(?:setUp|tearDown|test[A-Za-z_]\w*|runsForEachTargetApplicationUIConfiguration)\z/
].freeze

MethodInfo = Struct.new(
  :path, :context, :context_kind, :kind, :start_offset, :terminator, :body_close,
  :return_type, :selector, :parameter_count,
  keyword_init: true
)

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) || component.include?("Manual_Add_ThirdParty")
  end
end

def source_files(roots, headers_only: false, include_excluded: false)
  pattern = headers_only ? "*.h" : "*.{h,m,mm}"
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", pattern))
  end.uniq.reject { |path| !include_excluded && excluded?(Pathname(path)) }.sort
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
          masked.setbyte(index, 32) unless bytes[index] == "\n"; index += 1
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

def context_intervals(masked)
  tokens = []
  masked.to_enum(:scan, /@(interface|implementation|protocol)\s+([A-Za-z_]\w*)|@end/).each do
    match = Regexp.last_match
    if match[1]
      tokens << [match.begin(0), :open, match[2], match[1]]
    else
      tokens << [match.begin(0), :close, nil, nil]
    end
  end
  intervals = []
  stack = []
  tokens.each do |offset, action, name, kind|
    if action == :open
      stack << [offset, name, kind]
    elsif stack.any?
      opening, context, context_kind = stack.pop
      intervals << [opening, offset, context, context_kind]
    end
  end
  stack.each { |opening, context, kind| intervals << [opening, masked.length, context, kind] }
  intervals
end

def context_at(intervals, offset)
  interval = intervals.reverse.find { |opening, closing, _, _| opening <= offset && offset <= closing }
  interval ? interval[2, 2] : ["<global>", "global"]
end

def parse_methods(path, source, masked, intervals)
  methods = []
  offset = 0
  while (match = masked.match(/^[ \t]*([+-])[ \t]*\(/m, offset))
    opening = masked.index("(", match.begin(0))
    closing = matching_delimiter(masked, opening, 40, 41)
    break unless closing
    terminator = signature_terminator(masked, closing + 1)
    break unless terminator

    signature = source[(closing + 1)...terminator].strip.gsub(/\s+/, " ")
    labels = signature.scan(/\b([A-Za-z_]\w*)\s*:/).flatten
    selector = labels.empty? ? signature[/\A([A-Za-z_]\w*)/, 1] : "#{labels.join(':')}:"
    body_close = masked.getbyte(terminator) == 123 ? matching_delimiter(masked, terminator, 123, 125) : nil
    context, context_kind = context_at(intervals, match.begin(0))
    methods << MethodInfo.new(
      path: path,
      context: context,
      context_kind: context_kind,
      kind: match[1],
      start_offset: match.begin(0),
      terminator: terminator,
      body_close: body_close,
      return_type: source[(opening + 1)...closing].strip,
      selector: selector,
      parameter_count: labels.length
    ) if selector
    offset = body_close ? body_close + 1 : terminator + 1
  end
  methods
end

def block_return?(return_type)
  return_type.include?("(^") ||
    return_type.match?(/\b(?:Jobs|jobs)[A-Za-z_]\w*Blocks?\b/) ||
    return_type.match?(/\b\w+_block_t\b/)
end

def property_accessors(source, masked, intervals)
  accessors = Hash.new { |hash, key| hash[key] = Set.new }
  [/@property\b.*?;/m, /\bProp(?:_[A-Za-z_]\w*)?\s*\([^)]*\)\s*.*?;/m].each do |pattern|
    masked.to_enum(:scan, pattern).each do
      match = Regexp.last_match
      statement = source[match.begin(0)...match.end(0)]
      name = statement[/([A-Za-z_]\w*)\s*;\s*\z/m, 1]
      next unless name
      context, = context_at(intervals, match.begin(0))
      accessors[context] << (statement[/\bgetter\s*=\s*([A-Za-z_]\w*)/, 1] || name)
      accessors[context] << (statement[/\bsetter\s*=\s*([A-Za-z_]\w*:)/, 1] || "set#{name[0].upcase}#{name[1..]}:") unless statement.match?(/\breadonly\b/)
    end
  end
  accessors
end

def referenced_selectors(source)
  contract_source = source.lines.reject do |line|
    line.include?("JobsBlockInstanceMethodIMP") || line.include?("JobsBlockClassMethodIMP")
  end.join
  contract_source.scan(/@selector\s*\(\s*([A-Za-z_]\w*(?::[A-Za-z_]\w*)*:?)\s*\)/).flatten.to_set |
    contract_source.scan(/NSSelectorFromString\s*\(\s*@"([A-Za-z_]\w*(?::[A-Za-z_]\w*)*:?)"\s*\)/).flatten.to_set
end

options = { apply: false, contract_roots: [] }
OptionParser.new do |parser|
  parser.banner = "Usage: remove_oc_redundant_block_wrappers.rb [options] PATH..."
  parser.on("--contract-root PATH", "System or third-party headers; repeatable") { |value| options[:contract_roots] << value }
  parser.on("--apply", "Remove non-contract traditional wrappers already represented by Blocks") { options[:apply] = true }
end.parse!
abort "At least one source root is required" if ARGV.empty?

sources = {}
methods = []
accessors = Hash.new { |hash, key| hash[key] = Set.new }
selector_references = Set.new
protocol_selectors = Set.new

source_files(ARGV).each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)
  masked = mask_non_code(source)
  intervals = context_intervals(masked)
  parsed = parse_methods(path, source, masked, intervals)
  sources[path] = source
  methods.concat(parsed)
  property_accessors(source, masked, intervals).each { |context, values| accessors[context].merge(values) }
  selector_references.merge(referenced_selectors(source))
  parsed.select { |method| method.context_kind == "protocol" }.each { |method| protocol_selectors << method.selector }
end

external_contract_selectors = Set.new
source_files(options[:contract_roots], headers_only: true, include_excluded: true).each do |path|
  source = File.binread(path)
  next unless source.dup.force_encoding(Encoding::UTF_8).valid_encoding?
  masked = mask_non_code(source)
  parse_methods(path, source, masked, context_intervals(masked)).each do |method|
    external_contract_selectors << method.selector
  end
end

block_keys = methods.select { |method| block_return?(method.return_type) && method.parameter_count.zero? }
                    .to_set { |method| [method.context, method.kind, method.selector] }
wrapper_keys = Set.new
keep_counts = Hash.new(0)

methods.each do |method|
  next unless method.body_close && method.parameter_count == 1 && !block_return?(method.return_type)
  base = method.selector.delete_suffix(":")
  next unless block_keys.include?([method.context, method.kind, base])
  body = sources.fetch(method.path)[method.terminator..method.body_close]
  next unless body.include?("JobsBlock#{method.kind == '-' ? 'Instance' : 'Class'}MethodIMP")
  next unless body.include?("@selector(#{base})")

  reason = if accessors[method.context].include?(method.selector)
             "property-accessor"
           elsif method.selector.match?(OBJC_METHOD_FAMILIES)
             "objc-family"
           elsif FIXED_SELECTORS.include?(method.selector)
             "runtime-contract"
           elsif SYSTEM_CALLBACK_PATTERNS.any? { |pattern| method.selector.match?(pattern) }
             "system-callback"
           elsif selector_references.include?(method.selector)
             "selector-reference"
           elsif protocol_selectors.include?(method.selector)
             "protocol-contract"
           elsif external_contract_selectors.include?(method.selector)
             "external-contract"
           end
  if reason
    keep_counts[reason] += 1
  else
    wrapper_keys << [method.context, method.kind, method.selector]
  end
end

edits_by_path = Hash.new { |hash, key| hash[key] = [] }
methods.each do |method|
  key = [method.context, method.kind, method.selector]
  next unless wrapper_keys.include?(key)
  next if block_return?(method.return_type) || method.parameter_count != 1

  ending = method.body_close ? method.body_close + 1 : method.terminator + 1
  ending += 1 while ending < sources.fetch(method.path).bytesize && [10, 13].include?(sources.fetch(method.path).getbyte(ending))
  edits_by_path[method.path] << [method.start_offset, ending]
end

changed_files = 0
removed_methods = 0
edits_by_path.each do |path, edits|
  next if edits.empty?
  updated = sources.fetch(path).dup
  edits.sort_by(&:first).reverse_each { |start_offset, end_offset| updated[start_offset...end_offset] = "" }
  updated.gsub!(/\n{3,}/, "\n\n")
  File.binwrite(path, updated) if options[:apply]
  puts [options[:apply] ? "updated" : "would-update", path, edits.length].join("\t")
  changed_files += 1
  removed_methods += edits.length
end

warn "wrapper_selectors=#{wrapper_keys.length} methods=#{removed_methods} files=#{changed_files} kept=#{keep_counts.sort.map { |name, count| "#{name}:#{count}" }.join(',')} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
