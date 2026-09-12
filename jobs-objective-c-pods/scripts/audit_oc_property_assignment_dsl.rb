#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"

KNOWN_RECEIVER_TYPE_ALIASES = {
  # JobsAppTool 是返回 JobsAppTools 单例的宏，不是 Objective-C 类名。
  "JobsAppTool" => "JobsAppTools"
}.freeze
require "optparse"
require "pathname"
require "set"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual JobsModel@Pods build DerivedData
].freeze

BUILTIN_SUPERCLASSES = {
  "UIResponder" => "NSObject",
  "UIView" => "UIResponder",
  "UIControl" => "UIView",
  "UIButton" => "UIControl",
  "UILabel" => "UIView",
  "UIImageView" => "UIView",
  "UIScrollView" => "UIView",
  "UITableView" => "UIScrollView",
  "UICollectionView" => "UIScrollView",
  "UITextField" => "UIControl",
  "UITextView" => "UIScrollView",
  "UITableViewCell" => "UIView",
  "UICollectionViewCell" => "UIView",
  "UICollectionReusableView" => "UIView",
  "UIViewController" => "UIResponder",
  "UINavigationController" => "UIViewController",
  "UITabBarController" => "UIViewController",
  "UIGestureRecognizer" => "NSObject",
  "UITapGestureRecognizer" => "UIGestureRecognizer",
  "UIPanGestureRecognizer" => "UIGestureRecognizer",
  "UILongPressGestureRecognizer" => "UIGestureRecognizer",
  "CALayer" => "NSObject",
  "CAShapeLayer" => "CALayer",
  "CAGradientLayer" => "CALayer",
  "AVPlayerLayer" => "CALayer",
  "CAAnimation" => "NSObject",
  "CAPropertyAnimation" => "CAAnimation",
  "CABasicAnimation" => "CAPropertyAnimation",
  "CAKeyframeAnimation" => "CAPropertyAnimation",
  "CAAnimationGroup" => "CAAnimation",
  "CATransition" => "CAAnimation",
  "NSFormatter" => "NSObject",
  "NSDateFormatter" => "NSFormatter",
  "NSMutableURLRequest" => "NSURLRequest"
}.freeze

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) ||
      component.include?("Manual_Add_ThirdParty")
  end
end

def source_files(roots, excluded_fragments)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{h,m,mm}"))
  end.uniq.reject do |path|
    excluded?(Pathname(path)) || excluded_fragments.any? { |fragment| path.include?(fragment) }
  end.sort
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

def method_intervals(source, masked)
  intervals = []
  offset = 0
  while (match = masked.match(/^[ \t]*[+-][ \t]*\(/m, offset))
    opening = masked.index("(", match.begin(0))
    closing = matching_delimiter(masked, opening, 40, 41)
    break unless closing
    terminator = signature_terminator(masked, closing + 1)
    break unless terminator
    signature = source[(closing + 1)...terminator].strip.gsub(/\s+/, " ")
    labels = signature.scan(/\b([A-Za-z_]\w*)\s*:/).flatten
    selector = labels.empty? ? signature[/\A([A-Za-z_]\w*)/, 1] : "#{labels.join(':')}:"
    body_close = masked.getbyte(terminator) == 123 ? matching_delimiter(masked, terminator, 123, 125) : nil
    intervals << [terminator, body_close, selector] if body_close && selector
    offset = body_close ? body_close + 1 : terminator + 1
  end
  intervals
end

def selector_at(intervals, offset)
  interval = intervals.find { |opening, closing, _| opening <= offset && offset <= closing }
  interval&.last
end

def block_return?(return_type)
  return_type.match?(/\b(?:Jobs|jobs)[A-Za-z_]\w*Blocks?\b/) ||
    return_type.match?(/\b\w+_block_t\b/)
end

def owner_regions(source, masked)
  regions = []
  offset = 0
  pattern = /@(interface|implementation)\s+([A-Za-z_]\w*)(?:\s*\([^)]*\))?(?:\s*:\s*([A-Za-z_]\w*))?/
  while (match = masked.match(pattern, offset))
    ending = masked.index(/@end\b/, match.end(0))
    break unless ending
    regions << [match.begin(0), ending + 4, match[2], match[3]]
    offset = ending + 4
  end
  regions
end

def owner_at(regions, offset)
  region = regions.find { |opening, closing, _owner, _superclass| opening <= offset && offset <= closing }
  region && region[2]
end

def declared_properties(source, masked, regions)
  properties = Hash.new { |hash, owner| hash[owner] = {} }
  patterns = [
    /\bProp_[A-Za-z_]\w*\s*\([^)]*\)\s*(?:__kindof\s+)?([A-Za-z_]\w*)(?:\s*<[^;>]+>)?\s*\*?\s*(?:_Nullable\s+|_Nonnull\s+)?([A-Za-z_]\w*)\b[^;]*;/,
    /@property\s*\([^)]*\)\s*(?:__kindof\s+)?([A-Za-z_]\w*)(?:\s*<[^;>]+>)?\s*\*?\s*(?:_Nullable\s+|_Nonnull\s+)?([A-Za-z_]\w*)\b[^;]*;/
  ]
  patterns.each do |pattern|
    masked.to_enum(:scan, pattern).each do
      match = Regexp.last_match
      owner = owner_at(regions, match.begin(0))
      properties[owner][match[2]] = match[1] if owner
    end
  end
  properties
end

def declared_zero_argument_getters(source, masked, regions)
  getters = Hash.new { |hash, owner| hash[owner] = {} }
  pattern = /^[ \t]*[+-][ \t]*\([ \t]*(?:(?:_Nullable|_Nonnull|nullable|nonnull)[ \t]+)?(?:__kindof[ \t]+)?([A-Za-z_]\w*)(?:[ \t]*<[^\r\n>]+>)?[ \t]*\*?[ \t]*(?:_Nullable|_Nonnull|nullable|nonnull)?[ \t]*\)[ \t]*([a-z_][A-Za-z0-9_]*)\b[^;{\r\n]*(?=[;{])/m
  masked.to_enum(:scan, pattern).each do
    match = Regexp.last_match
    owner = owner_at(regions, match.begin(0))
    getters[owner][match[2]] ||= (match[1] == "instancetype" ? owner : match[1]) if owner
  end
  getters
end

def local_type_for(identifier, source, masked, offset)
  prefix = masked.byteslice(0...offset)
  # 兼容历史代码中的 `UIView __kindof *obj` 与标准 `__kindof UIView *obj` 两种顺序。
  pattern = /(?:__kindof\s+)?([A-Za-z_]\w*)(?:\s+__kindof)?(?:\s*<[^;=()]+>)?\s*\*\s*(?:_Nullable\s+|_Nonnull\s+)?\)?\s*#{Regexp.escape(identifier)}\b/
  matches = prefix.to_enum(:scan, pattern).map { Regexp.last_match[1] }
  matches.last
end

def property_type_for_owner(owner, property, properties_by_owner, superclasses)
  visited = Set.new
  current = owner
  while current && !visited.include?(current)
    return properties_by_owner[current][property] if properties_by_owner[current].key?(property)
    visited << current
    current = superclasses[current]
  end
  nil
end

def resolve_receiver_type(receiver, source, masked, offset, owner, properties_by_owner, superclasses)
  parts = receiver.split(".").map(&:strip)
  first = parts.shift
  type = if first == "self"
           owner
         elsif first == "weak_self"
           owner
         elsif first&.start_with?("_") && owner
           property_type_for_owner(owner, first.delete_prefix("_"), properties_by_owner, superclasses)
         elsif first&.match?(/\A[A-Z]/)
           KNOWN_RECEIVER_TYPE_ALIASES.fetch(first, first)
         else
           local_type_for(first.to_s, source, masked, offset)
         end
  parts.each do |property|
    break unless type
    type = property_type_for_owner(type, property, properties_by_owner, superclasses)
  end
  type
end

def selector_declaration_paths(type, selector, declarations_by_owner_selector, superclasses)
  visited = Set.new
  current = type
  paths = Set.new
  while current && !visited.include?(current)
    paths.merge(declarations_by_owner_selector[[current, selector]])
    visited << current
    current = superclasses[current]
  end
  paths
end

def imported_paths_for(path, sources, headers_by_basename)
  source = sources.fetch(path).first
  source.scan(/^[ \t]*#[ \t]*(?:import|include)[ \t]*[<\"]([^>\"]+)[>\"]/).flatten.each_with_object(Set.new) do |token, paths|
    relative = File.expand_path(token, File.dirname(path))
    paths << relative if sources.key?(relative)
    basename = File.basename(token)
    candidates = headers_by_basename[basename]
    module_name = token.include?("/") ? token.split("/", 2).first : nil
    preferred = if module_name
                  candidates.select do |candidate|
                    candidate.include?("/#{module_name}@Pods/") || candidate.include?("/#{module_name}/")
                  end
                else
                  []
                end
    (preferred.empty? ? candidates : preferred).each { |candidate| paths << candidate }
  end
end

def visible_paths_for(path, sources, headers_by_basename, cache)
  return cache[path] if cache.key?(path)

  visible = Set.new([path])
  queue = imported_paths_for(path, sources, headers_by_basename).to_a
  until queue.empty?
    imported = queue.shift
    next if visible.include?(imported)

    visible << imported
    queue.concat(imported_paths_for(imported, sources, headers_by_basename).to_a) if sources.key?(imported)
  end
  cache[path] = visible
end

def owner_has_property?(owner, property, properties_by_owner, superclasses)
  visited = Set.new
  current = owner
  while current && !visited.include?(current)
    return true if properties_by_owner[current].key?(property)
    visited << current
    current = superclasses[current]
  end
  false
end

def dsl_selector(property, owner, properties_by_owner, superclasses)
  # UIView 已用 `byCenter(x, y)` 表达双标量定位；`center` 属性写入必须走
  # 单 CGPoint 的 `byCenterPoint(...)`，不能只按属性名机械拼接同名 Block。
  return "byCenterPoint" if property == "center"
  if property.start_with?("gk_")
    suffix = property.delete_prefix("gk_")
    return "byGK#{suffix[0].upcase}#{suffix[1..]}"
  end

  base = property
  if property.match?(/\Ais[A-Z]/)
    stripped = property.delete_prefix("is")
    counterpart = "#{stripped[0].downcase}#{stripped[1..]}"
    # 同一 owner 同时存在 `isXxx` 与 `xxx` 时，保留 `is`，避免两个不同类型的
    # 属性机械收敛成同一个 Block selector。
    base = stripped unless owner_has_property?(owner, counterpart, properties_by_owner, superclasses)
  end
  "by#{base[0].upcase}#{base[1..]}"
end

options = { apply: false, self_only: false, excluded_fragments: [], type_roots: [] }
OptionParser.new do |parser|
  parser.banner = "Usage: audit_oc_property_assignment_dsl.rb [--apply] [--exclude-fragment TEXT] PATH..."
  parser.on("--apply", "Rewrite single-line property assignments when a matching Block DSL exists") { options[:apply] = true }
  parser.on("--self-only", "Only rewrite direct self.property assignments; use as the safe bulk pass") { options[:self_only] = true }
  parser.on("--exclude-fragment TEXT", "Skip paths containing TEXT; repeatable for ownership boundaries") do |fragment|
    options[:excluded_fragments] << fragment
  end
  parser.on("--type-root PATH", "Read-only header root for system/third-party receiver property types; repeatable") do |path|
    options[:type_roots] << path
  end
end.parse!
abort "At least one path is required" if ARGV.empty?

sources = {}
dsl_selectors = Set.new
dsl_selectors_by_path = Hash.new { |hash, path| hash[path] = Set.new }
dsl_selectors_by_owner = Hash.new { |hash, owner| hash[owner] = Set.new }
dsl_declarations_by_owner_selector = Hash.new { |hash, key| hash[key] = Set.new }
properties_by_owner = Hash.new { |hash, owner| hash[owner] = {} }
superclasses = BUILTIN_SUPERCLASSES.dup
owner_regions_by_path = {}
source_files(ARGV, options[:excluded_fragments]).each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)
  masked = mask_non_code(source)
  sources[path] = [source, masked]
  regions = owner_regions(source, masked)
  owner_regions_by_path[path] = regions
  regions.each { |_opening, _closing, owner, superclass| superclasses[owner] ||= superclass if superclass }
  declared_properties(source, masked, regions).each do |owner, properties|
    properties_by_owner[owner].merge!(properties)
  end
  declared_zero_argument_getters(source, masked, regions).each do |owner, getters|
    getters.each { |name, type| properties_by_owner[owner][name] ||= type }
  end
  masked.to_enum(:scan, /^[ \t]*[+-][ \t]*\(([^\r\n()]*)\)[ \t]*(by[A-Z]\w*)\b/m).each do
    match = Regexp.last_match
    return_type = source[match.begin(1)...match.end(1)]
    if block_return?(return_type)
      dsl_selectors << match[2]
      dsl_selectors_by_path[path] << match[2]
      owner = owner_at(regions, match.begin(0))
      if owner
        dsl_selectors_by_owner[owner] << match[2]
        dsl_declarations_by_owner_selector[[owner, match[2]]] << path
      end
    end
  end
end

# 系统 SDK 与第三方 Pods 只参与 receiver/property 类型解析，不进入改写、DSL 可见性
# 或 Jobs 所有权判断。
type_header_paths = options[:type_roots].flat_map do |root|
  expanded = File.expand_path(root)
  File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.h"))
end.uniq.sort - sources.keys
type_header_paths.each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding?
  masked = mask_non_code(source)
  regions = owner_regions(source, masked)
  regions.each { |_opening, _closing, owner, superclass| superclasses[owner] ||= superclass if superclass }
  declared_properties(source, masked, regions).each do |owner, properties|
    properties.each { |name, type| properties_by_owner[owner][name] ||= type }
  end
  declared_zero_argument_getters(source, masked, regions).each do |owner, getters|
    getters.each { |name, type| properties_by_owner[owner][name] ||= type }
  end
end

headers_by_basename = Hash.new { |hash, basename| hash[basename] = [] }
sources.each_key do |path|
  headers_by_basename[File.basename(path)] << path if File.extname(path) == ".h"
end
visible_paths_cache = {}

counts = Hash.new(0)
changed_files = 0
sources.each do |path, (source, masked)|
  next unless %w[.m .mm].include?(File.extname(path))
  intervals = method_intervals(source, masked)
  owner_regions = owner_regions_by_path[path]
  struct_receivers = masked.scan(/\b(?:CGRect|CGSize|CGPoint|CGVector|UIEdgeInsets|NSDirectionalEdgeInsets|NSRange|CGAffineTransform|CATransform3D)\s+([A-Za-z_]\w*)/).flatten.to_set
  edits = []
  line_offset = 0
  source.lines.each_with_index do |line, line_index|
    masked_line = masked[line_offset, line.bytesize]
    line_offset += line.bytesize
    next if masked_line.lstrip.start_with?("#", "@synthesize", "@dynamic")

    # 一行包含多条语句时不能把后续语句吞进 DSL 参数；这类表达留给人工拆行后再转换。
    match = masked_line.match(/\A([ \t]*)([A-Za-z_]\w*(?:\s*\.\s*[A-Za-z_]\w*)+)\s*=\s*(?![=])([^;]+?)\s*;\s*\z/)
    next unless match

    lhs = source[(line_offset - line.bytesize + match.begin(2))...(line_offset - line.bytesize + match.end(2))]
    equals_offset = masked_line.index("=", match.end(2))
    semicolon_offset = masked_line.rindex(";")
    next unless equals_offset && semicolon_offset && equals_offset < semicolon_offset
    rhs = line.byteslice((equals_offset + 1)...semicolon_offset).strip
    rhs = rhs.sub(/;+\z/, "").rstrip
    lhs_parts = lhs.split(".").map(&:strip)
    property = lhs_parts.pop
    receiver = lhs_parts.join(".")
    # CGRect/CGSize 等 C 结构体字段不是 Objective-C 消息接收者，不能生成
    # `frame.size.byWidth(...)` 这类看似 DSL、实际无法编译的表达。
    next if struct_receivers.include?(lhs_parts.first)
    next if options[:self_only] && receiver != "self"
    assignment_offset = line_offset - line.bytesize + match.begin(0)
    current_owner = owner_at(owner_regions, assignment_offset)
    receiver_type = resolve_receiver_type(receiver,
                                          source,
                                          masked,
                                          assignment_offset,
                                          current_owner,
                                          properties_by_owner,
                                          superclasses)
    selector = dsl_selector(property, receiver_type, properties_by_owner, superclasses)
    current_selector = selector_at(intervals, assignment_offset)
    implementation_selectors = [selector, "by#{property[0].upcase}#{property[1..]}"]
    kernel_selector = current_selector && (
      current_selector.start_with?("by") ||
      current_selector.end_with?("By") ||
      current_selector.match?(/\Aset[A-Z_]/) ||
      current_selector.match?(/(?:\A|_)set[A-Z_]/) ||
      current_selector.start_with?("init") ||
      current_selector.match?(/\A(?:invalidate|teardown)/i) ||
      current_selector == "jobs_chainProxy" ||
      current_selector == "dealloc"
    )
    if kernel_selector || (receiver == "self" && implementation_selectors.include?(current_selector))
      counts["dsl-implementation"] += 1
      next
    end

    declaration_paths = receiver_type ? selector_declaration_paths(receiver_type,
                                                                    selector,
                                                                    dsl_declarations_by_owner_selector,
                                                                    superclasses) : Set.new
    visible_paths = visible_paths_for(path, sources, headers_by_basename, visible_paths_cache)
    visible_declaration = !(declaration_paths & visible_paths).empty?
    status = if visible_declaration
               "convertible"
             elsif receiver_type && declaration_paths.any?
               "missing-import"
             elsif receiver_type
               "missing-dsl"
             else
               "unverified-receiver"
             end
    counts[status] += 1
    declaration_source = declaration_paths.to_a.sort.join(",")
    puts [status, path, line_index + 1, lhs, selector, receiver_type || "unknown", declaration_source].join("\t") unless options[:apply] && status == "convertible"
    next unless options[:apply] && status == "convertible"

    replacement = "#{match[1]}#{receiver}.#{selector}(#{rhs});"
    replacement << line[/\r?\n\z/].to_s
    edits << [line_offset - line.bytesize, line_offset, replacement]
  end

  next if edits.empty?
  updated = source.dup
  edits.reverse_each { |start_offset, end_offset, replacement| updated[start_offset...end_offset] = replacement }
  File.binwrite(path, updated)
  puts ["updated", path, edits.length].join("\t")
  changed_files += 1
end

warn "#{counts.sort.map { |name, count| "#{name}=#{count}" }.join(' ')} dsl_selectors=#{dsl_selectors.length} changed_files=#{changed_files} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
exit((counts["missing-dsl"].positive? || counts["missing-import"].positive? || counts["unverified-receiver"].positive?) ? 2 : 0)
