#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "optparse"
require "pathname"
require "set"
require_relative "jobs_oc_ownership"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual JobsModel@Pods build DerivedData
].freeze

# 部分系统/历史类的属性声明会被宏、module 边界或条件编译隐藏；这里只记录已经由
# SDK/现有源码核实过的精确类型，避免以调用实参反推并生成错误 ABI。
KNOWN_PROPERTY_TYPES = {
  ["ASEditableTextNode", "borderColor"] => "CGColorRef",
  ["ASTableNode", "dataSource"] => "id<ASTableDataSource>",
  ["ASTableNode", "delegate"] => "id<ASTableDelegate>",
  ["AVAssetWriterInput", "expectsMediaDataInRealTime"] => "BOOL",
  ["AVCaptureSession", "sessionPreset"] => "NSString *",
  ["JobsCustomTabBarVC", "selectedIndex"] => "NSUInteger",
  ["JobsCustomTabBarVC", "viewControllers"] => "NSArray<__kindof UIViewController *> *",
  ["JobsTabBar", "y"] => "CGFloat",
  ["JobsTabBarVC", "selectedIndex"] => "NSUInteger",
  ["JobsTabBarVC", "viewControllers"] => "NSArray<__kindof UIViewController *> *",
  ["LOTAnimationView", "sizer"] => "CGSize",
  ["LZTabBarController", "selectedIndex"] => "NSUInteger",
  ["LZTabBarController", "viewControllers"] => "NSArray<__kindof UIViewController *> *",
  ["LiveChat", "licenseId"] => "NSString *",
  ["NSTimer", "tolerance"] => "NSTimeInterval",
  ["UIControl", "uxy_ignoreEvent"] => "BOOL"
}.freeze

FORWARD_BEGIN = "// JOBS_PROPERTY_DSL_FORWARD_AUTOGEN_BEGIN"
FORWARD_END = "// JOBS_PROPERTY_DSL_FORWARD_AUTOGEN_END"
TYPEDEF_BEGIN = "// JOBS_PROPERTY_DSL_TYPEDEF_AUTOGEN_BEGIN"
TYPEDEF_END = "// JOBS_PROPERTY_DSL_TYPEDEF_AUTOGEN_END"
BUILTIN_SUPERCLASSES = {
  "UIResponder" => "NSObject", "UIView" => "UIResponder", "UIControl" => "UIView",
  "UIButton" => "UIControl", "UILabel" => "UIView", "UIImageView" => "UIView",
  "UIScrollView" => "UIView", "UITableView" => "UIScrollView", "UICollectionView" => "UIScrollView",
  "UITextField" => "UIControl", "UITextView" => "UIScrollView", "UIViewController" => "UIResponder",
  "UINavigationController" => "UIViewController", "UITabBarController" => "UIViewController",
  "CALayer" => "NSObject", "CAAnimation" => "NSObject", "CAAnimationGroup" => "CAAnimation",
  "NSFormatter" => "NSObject", "NSDateFormatter" => "NSFormatter",
  "NSMutableURLRequest" => "NSURLRequest"
}.freeze

Region = Struct.new(:kind, :owner, :category, :superclass, :opening, :closing, keyword_init: true)

def excluded?(path, fragments)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) || component.include?("Manual_Add_ThirdParty")
  end || fragments.any? { |fragment| path.to_s.include?(fragment) }
end

def source_files(roots, fragments)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{h,m,mm}"))
  end.uniq.reject { |path| excluded?(Pathname(path), fragments) }.sort
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

def regions(source, masked)
  values = []
  offset = 0
  pattern = /@(interface|implementation|protocol)\s+([A-Za-z_]\w*)(?:\s*\(([^)]*)\))?(?:\s*:\s*([A-Za-z_]\w*))?/
  while (match = masked.match(pattern, offset))
    ending = masked.index(/@end\b/, match.end(0))
    break unless ending
    values << Region.new(kind: match[1], owner: match[2], category: match[3], superclass: match[4],
                         opening: match.begin(0), closing: ending)
    offset = ending + 4
  end
  values
end

def property_declarations(source, region)
  body = mask_non_code(source)[region.opening...region.closing]
  declarations = {}
  body.scan(/(?:@property(?:\s*\([^)]*\))?|Prop_[A-Za-z_]\w*\s*\([^)]*\))\s*([^;]+);/m) do |match|
    declaration = match.first.gsub(/\s+/, " ").strip
    declaration = declaration.split(/\s+(?=(?:API_AVAILABLE|API_UNAVAILABLE|API_DEPRECATED|NS_AVAILABLE|NS_DEPRECATED|NS_SWIFT_NAME|NS_REFINED_FOR_SWIFT|UI_APPEARANCE_SELECTOR)\b)/, 2).first
    block = declaration.match(/\A(.+?)\(\s*\^\s*([A-Za-z_]\w*)\s*\)\s*(\(.*\))\z/m)
    if block
      declarations[block[2]] ||= "#{block[1].strip} (^)(#{block[3][1...-1].strip})"
      next
    end
    name = declaration[/([A-Za-z_]\w*)\s*\z/, 1]
    next unless name
    type = declaration[0...declaration.rindex(name)].strip
    declarations[name] ||= type unless type.empty?
  end
  declarations
end

def class_property_names(source, region)
  body = mask_non_code(source)[region.opening...region.closing]
  names = Set.new
  body.scan(/(?:@property(?:\s*\(([^)]*)\))?|Prop_[A-Za-z_]\w*\s*\(([^)]*)\))\s*([^;]+);/m) do |property_attrs, macro_attrs, raw_declaration|
    attributes = (property_attrs || macro_attrs).to_s.split(",").map(&:strip)
    next unless attributes.include?("class")
    declaration = raw_declaration.gsub(/\s+/, " ").strip
    declaration = declaration.split(/\s+(?=(?:API_AVAILABLE|API_UNAVAILABLE|API_DEPRECATED|NS_AVAILABLE|NS_DEPRECATED|NS_SWIFT_NAME|NS_REFINED_FOR_SWIFT|UI_APPEARANCE_SELECTOR)\b)/, 2).first
    block = declaration.match(/\A(.+?)\(\s*\^\s*([A-Za-z_]\w*)\s*\)\s*(\(.*\))\z/m)
    if block
      names << block[2]
      next
    end
    name = declaration[/([A-Za-z_]\w*)\s*\z/, 1]
    names << name if name
  end
  names
end

def split_arguments(arguments)
  values = []
  start = 0
  round = 0
  angle = 0
  square = 0
  arguments.bytes.each_with_index do |byte, index|
    case byte
    when 40 then round += 1
    when 41 then round -= 1
    when 60 then angle += 1
    when 62 then angle -= 1
    when 91 then square += 1
    when 93 then square -= 1
    when 44
      next unless round.zero? && angle.zero? && square.zero?
      values << arguments[start...index]
      start = index + 1
    end
  end
  values << arguments[start..]
  values
end

def parameter_type(argument)
  value = argument.to_s.strip
  return "void" if value.empty? || value == "void"
  return value if value.include?("(^")
  without_name = value.sub(/\b[A-Za-z_]\w*\s*\z/, "").strip
  without_name.empty? ? value : without_name
end

def normalize_type(type)
  type.to_s
      .gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__nonnull|__nullable|__kindof)\b/, "")
      .gsub(/\b(?:__autoreleasing|__strong|__weak|__unsafe_unretained|const|volatile|NS_NOESCAPE)\b/, "")
      .gsub(/\binstancetype\b/, "id")
      .gsub(/\s+/, "")
end

def canonical_type(type)
  type.to_s.gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__nonnull|__nullable|NS_NOESCAPE)\b/, "")
      .gsub(/\s+/, " ").strip
end

def argument_declaration(type, name = "data")
  value = canonical_type(type)
  block = value.match(/\A(.+?)\(\s*\^\s*\)\s*\((.*)\)\s*\z/m)
  return "#{block[1].strip} (^ _Nullable #{name})(#{block[2].strip})" if block
  nullable = value.include?("*") || value.match?(/\A(?:id|Class)\b/)
  "#{value}#{nullable ? ' _Nullable' : ''} #{name}"
end

def method_parameter_declaration(type, name = "data")
  value = canonical_type(type)
  block = value.match(/\A(.+?)\(\s*\^\s*\)\s*\((.*)\)\s*\z/m)
  return "(#{block[1].strip} (^ _Nullable)(#{block[2].strip}))#{name}" if block
  nullable = value.include?("*") || value.match?(/\A(?:id|Class)\b/)
  "(#{value}#{nullable ? ' _Nullable' : ''})#{name}"
end

def nullable_return(type)
  value = canonical_type(type).gsub(/\binstancetype\b/, "id")
  value.include?("*") ? "#{value} _Nullable" : value
end

def type_stem(type)
  normalized = normalize_type(type)
  return "Void" if normalized.empty? || normalized == "void"
  return "ID" if normalized == "id"
  value = normalized.scan(/[A-Za-z_]\w*/).reject { |token| %w[const struct enum].include?(token) }
                    .map { |token| token == "id" ? "ID" : token.sub(/\A_+/, "") }
                    .reject(&:empty?).join
  value = "Type" if value.empty?
  value.length > 72 ? "#{value[0, 56]}#{Digest::SHA1.hexdigest(normalized)[0, 10]}" : value
end

def existing_typedefs(block_roots)
  entries = {}
  names = Set.new
  block_roots.flat_map { |root| Dir.glob(File.join(File.expand_path(root), "**", "*.h")) }.uniq.sort.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    source.scan(/typedef\b.*?;/m).each do |statement|
      match = statement.match(/\A\s*typedef\s+(.+?)\(\s*\^\s*([A-Za-z_]\w*)\s*\)\s*\((.*)\)\s*;/m)
      next unless match
      values = match[3].strip == "void" ? [] : split_arguments(match[3])
      next if values.length > 1
      parameter = values.empty? ? "void" : parameter_type(values.first)
      entries[[normalize_type(match[1]), normalize_type(parameter)]] ||= match[2]
      names << match[2]
    end
  end
  [entries, names]
end

def block_aliases(paths)
  aliases = {}
  paths.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    source.scan(/typedef\b.*?;/m).each do |statement|
      match = statement.match(/\A\s*typedef\s+(.+?)\(\s*\^\s*([A-Za-z_]\w*)\s*\)\s*\((.*)\)\s*;/m)
      next unless match
      aliases[match[2]] ||= "#{match[1].strip} (^)(#{match[3].strip})"
    end
  end
  aliases
end

def expanded_parameter(type, aliases, globally_available_names)
  alias_name = canonical_type(type).gsub(/\s+/, "")
  return type if globally_available_names.include?(alias_name)
  aliases.fetch(alias_name, type)
end

def existing_section_lines(source, begin_marker, end_marker)
  match = source.match(/#{Regexp.escape(begin_marker)}\n?(.*?)\n?#{Regexp.escape(end_marker)}/m)
  match ? match[1].lines.map(&:strip).reject(&:empty?) : []
end

def replace_generated_section(source, begin_marker, end_marker, lines)
  section = ([begin_marker] + lines.sort.uniq + [end_marker]).join("\n")
  pattern = /#{Regexp.escape(begin_marker)}.*?#{Regexp.escape(end_marker)}/m
  return source.sub(pattern, section) if source.match?(pattern)
  anchor = source.index("// JOBS_INLINE_BLOCK_") || source.index("// JOBS_FUNCTIONAL_BLOCK_") || source.rindex(/^#endif\b/)
  abort "Unable to locate JobsBlock generated-section insertion point" unless anchor
  source.dup.insert(anchor, "#{section}\n\n")
end

def enum_declarations(paths)
  declarations = {}
  paths.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    source.scan(/typedef\s+NS_(ENUM|OPTIONS)\s*\(\s*([^,]+),\s*([A-Za-z_]\w*)\s*\)/) do |kind, base, name|
      declarations[name] ||= "typedef NS_#{kind}(#{base.strip}, #{name});"
    end
  end
  declarations
end

def string_typedef_declarations(paths)
  declarations = {}
  paths.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    source.scan(/typedef\s+NSString\s*\*\s*([A-Za-z_]\w*)\s+(NS_(?:TYPED_)?EXTENSIBLE_ENUM|NS_STRING_ENUM)\s*;/) do |name, attribute|
      declarations[name] ||= "typedef NSString *#{name} #{attribute};"
    end
  end
  declarations
end

options = { apply: false, reports: [], block_roots: [], forward_headers: [], return_headers: [], fragments: [], type_roots: [], local_category_fallback: false }
OptionParser.new do |parser|
  parser.banner = "Usage: synthesize_oc_property_owner_dsls.rb [options] PATH..."
  parser.on("--apply", "Write owner DSL methods and JobsBlock typedefs") { options[:apply] = true }
  parser.on("--report PATH", "Property audit TSV; repeatable") { |value| options[:reports] << value }
  parser.on("--block-root PATH", "JobsBlock root; repeatable") { |value| options[:block_roots] << value }
  parser.on("--forward-header PATH", "JobsBlockHeader.h target; repeatable") { |value| options[:forward_headers] << value }
  parser.on("--return-header PATH", "Return Block typedef target; repeatable") { |value| options[:return_headers] << value }
  parser.on("--type-root PATH", "Read-only header root for inherited/system/third-party property types") { |value| options[:type_roots] << value }
  parser.on("--local-category-fallback", "Generate a Jobs-owned local category when the receiver class is external") do
    options[:local_category_fallback] = true
  end
  parser.on("--exclude-fragment TEXT", "Skip matching paths") { |value| options[:fragments] << value }
end.parse!

abort "At least one source PATH is required" if ARGV.empty?
abort "--report, --block-root, --forward-header and --return-header are required" if
  options[:reports].empty? || options[:block_roots].empty? || options[:forward_headers].empty? || options[:return_headers].empty?

requested = Hash.new { |hash, owner| hash[owner] = Set.new }
callers_by_request = Hash.new { |hash, key| hash[key] = Set.new }
options[:reports].each do |report|
  File.foreach(report) do |line|
    columns = line.chomp.split("\t")
    next unless columns[0] == "missing-dsl" && columns.length >= 6
    requested[columns[5]] << [columns[4], columns[3].split(".").last]
    callers_by_request[[columns[5], columns[4], columns[3].split(".").last]] << columns[1]
  end
end

paths = source_files(ARGV, options[:fragments])
sources = {}
regions_by_path = {}
interfaces = Hash.new { |hash, owner| hash[owner] = [] }
implementations = Hash.new { |hash, owner| hash[owner] = [] }
properties = Hash.new { |hash, owner| hash[owner] = {} }
global_property_types = Hash.new { |hash, property| hash[property] = {} }
methods = Hash.new { |hash, owner| hash[owner] = Set.new }
class_methods = Hash.new { |hash, owner| hash[owner] = Set.new }
instance_methods = Hash.new { |hash, owner| hash[owner] = Set.new }
class_properties = Set.new
superclasses = BUILTIN_SUPERCLASSES.dup

paths.each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)
  masked = mask_non_code(source)
  file_regions = regions(source, masked)
  sources[path] = source
  regions_by_path[path] = file_regions
  file_regions.each do |region|
    superclasses[region.owner] ||= region.superclass if region.superclass
    if region.kind == "interface"
      interfaces[region.owner] << [path, region]
    elsif region.kind == "implementation"
      implementations[region.owner] << [path, region]
    end
    property_declarations(source, region).each do |name, type|
      properties[region.owner][name] ||= type
      global_property_types[name][normalize_type(type)] ||= type
    end
    class_property_names(source, region).each { |name| class_properties << [region.owner, name] }
    masked[region.opening...region.closing].scan(/^[ \t]*([+-])[ \t]*\([^\r\n]*\)[ \t]*([A-Za-z_]\w*)[ \t]*(?=[;{])/m) do |sign, selector|
      methods[region.owner] << selector
      (sign == "+" ? class_methods : instance_methods)[region.owner] << selector
    end
  end
end

type_header_paths = (ARGV + options[:type_roots]).flat_map do |root|
  expanded = File.expand_path(root)
  File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.h"))
end.uniq.sort - sources.keys
type_header_paths.each do |path|
  source = File.binread(path)
  utf8 = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8.valid_encoding?
  masked = mask_non_code(source)
  regions(source, masked).each do |region|
    next unless %w[interface protocol].include?(region.kind)
    superclasses[region.owner] ||= region.superclass if region.superclass
    property_declarations(source, region).each do |name, type|
      properties[region.owner][name] ||= type
      global_property_types[name][normalize_type(type)] ||= type
    end
    class_property_names(source, region).each { |name| class_properties << [region.owner, name] }
  end
end

def property_type(owner, property, properties, superclasses, global_property_types)
  return KNOWN_PROPERTY_TYPES[[owner, property]] if KNOWN_PROPERTY_TYPES.key?([owner, property])

  visited = Set.new
  current = owner
  while current && !visited.include?(current)
    return properties[current][property] if properties[current].key?(property)
    visited << current
    current = superclasses[current]
  end
  candidates = global_property_types[property]
  candidates.length == 1 ? candidates.values.first : nil
end

def preferred_region(entries, owner, extension)
  values = entries.select { |path, _region| File.extname(path) == extension }
  values.min_by do |path, region|
    normalized_path = path.tr("\\", "/")
    in_jobs_dsl = normalized_path.include?("/JobsOCDSL/")
    basename = File.basename(path, extension)
    main_owner = basename == owner && region.category.nil?
    exact_owner_dsl = basename == "#{owner}+DSL"
    dedicated_jobs_dsl = in_jobs_dsl && exact_owner_dsl
    system_supplement = in_jobs_dsl && normalized_path.include?("/JobsSystemAPIDSLSupplement/")
    ownership_rank = if main_owner
                       0
                     elsif exact_owner_dsl
                       1
                     elsif system_supplement
                       2
                     elsif dedicated_jobs_dsl
                       3
                     elsif region.category.to_s.empty?
                       4
                     elsif in_jobs_dsl
                       5
                     else
                       6
                     end
    [ownership_rank,
     path.length,
     path]
  end
end

typedefs, used_names = existing_typedefs(options[:block_roots])
globally_available_names = used_names.dup
aliases = block_aliases(paths + type_header_paths)
generated_typedefs = {}
plans = []

requested.sort.each do |owner, selector_properties|
  header_entry = preferred_region(interfaces[owner], owner, ".h") ||
                 preferred_region(interfaces[owner], owner, ".m") ||
                 preferred_region(interfaces[owner], owner, ".mm")
  implementation_entry = preferred_region(implementations[owner], owner, ".m") ||
                         preferred_region(implementations[owner], owner, ".mm")
  selector_properties.sort.each do |selector, property|
    callers = callers_by_request[[owner, selector, property]].to_a.sort
    type = property_type(owner, property, properties, superclasses, global_property_types)
    is_class_property = class_properties.include?([owner, property])
    owner_methods = is_class_property ? class_methods : instance_methods
    status = if owner_methods[owner].include?(selector)
               "selector-conflict"
             elsif type.nil?
               "missing-property-type"
             elsif header_entry.nil? && options[:local_category_fallback] && !callers.empty? && owner != "__kindof"
               "synthesizable-local-category"
             elsif header_entry.nil?
               "missing-owner-header"
             elsif implementation_entry.nil?
               "missing-owner-implementation"
             else
               "synthesizable"
    end
    if status.start_with?("synthesizable")
      implementation_type = expanded_parameter(type, aliases, globally_available_names)
      return_type = is_class_property ? "Class" : "__kindof #{owner} *"
      key = [normalize_type(return_type), normalize_type(implementation_type)]
      name = typedefs[key]
      unless name
        preferred = "JobsRet#{type_stem(owner)}By#{type_stem(type)}Block"
        name = preferred
        name = "#{preferred.sub(/Block\z/, '')}_#{Digest::SHA1.hexdigest(key.join('|'))[0, 10]}Block" if used_names.include?(name)
        used_names << name
        typedefs[key] = name
        generated_typedefs[key] = [name, return_type, implementation_type]
      end
      plans << [status, owner, property, selector, implementation_type, name, header_entry, implementation_entry, callers, is_class_property]
    else
      plans << [status, owner, property, selector, type || "unknown", "-", header_entry, implementation_entry, callers, is_class_property]
    end
  end
end

plans.each do |status, owner, property, selector, type, name, header_entry, implementation_entry, callers, is_class_property|
  puts [status, owner, property, selector, type, name, header_entry&.first || "-", implementation_entry&.first || "-", is_class_property ? "class" : "instance"].join("\t")
end
counts = plans.group_by(&:first).transform_values(&:length)
warn "#{counts.sort.map { |status, count| "#{status}=#{count}" }.join(' ')} generated_typedefs=#{generated_typedefs.length} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
exit 0 unless options[:apply]

declarations_by_target = Hash.new { |hash, key| hash[key] = [] }
implementations_by_target = Hash.new { |hash, key| hash[key] = [] }
local_category_plans = []
plans.each do |status, owner, property, selector, type, name, header_entry, implementation_entry, callers, is_class_property|
  if status == "synthesizable-local-category"
    local_category_plans << [owner, property, selector, type, name, callers, is_class_property]
    next
  end
  next unless status == "synthesizable"
  method_sign = is_class_property ? "+" : "-"
  block_return_type = is_class_property ? "Class" : "__kindof #{owner} *"
  declaration = "#{method_sign}(#{name} _Nonnull)#{selector};"
  setter_declaration = "#{method_sign}(void)set#{property[0].upcase}#{property[1..]}:#{method_parameter_declaration(type)};"
  implementation = <<~OBJC.rstrip
    #{method_sign}(#{name} _Nonnull)#{selector}{
        @jobs_weakify(self)
        return ^#{block_return_type} _Nullable(#{argument_declaration(type)}){
            @jobs_strongify(self)
            [self set#{property[0].upcase}#{property[1..]}:data];
            return self;
        };
    }
  OBJC
  declarations_by_target[[header_entry[0], owner, header_entry[1].opening]] << declaration
  declarations_by_target[[header_entry[0], owner, header_entry[1].opening]] << setter_declaration
  implementations_by_target[[implementation_entry[0], owner, implementation_entry[1].opening]] << implementation
end

edits_by_path = Hash.new { |hash, path| hash[path] = [] }
(declarations_by_target.keys + implementations_by_target.keys).map(&:first).uniq.each do |path|
  source = sources.fetch(path)
  file_regions = regions_by_path.fetch(path)
  declarations_by_target.each do |(target_path, owner, opening), lines|
    next unless target_path == path
    region = file_regions.find { |candidate| candidate.owner == owner && candidate.opening == opening }
    marker_begin = "// JOBS_PROPERTY_DSL_DECLARATION_AUTOGEN_BEGIN #{owner}"
    marker_end = "// JOBS_PROPERTY_DSL_DECLARATION_AUTOGEN_END #{owner}"
    missing_lines = lines.sort.uniq.reject { |line| source.include?(line) }
    next if missing_lines.empty?
    if source.include?(marker_begin)
      insertion = source.index(marker_end, source.index(marker_begin))
      edits_by_path[path] << [insertion, insertion, "#{missing_lines.join("\n")}\n"]
    else
      section = "#{marker_begin}\n#{missing_lines.join("\n")}\n#{marker_end}\n"
      edits_by_path[path] << [region.closing, region.closing, section]
    end
  end
  implementations_by_target.each do |(target_path, owner, opening), methods|
    next unless target_path == path
    region = file_regions.find { |candidate| candidate.owner == owner && candidate.opening == opening }
    marker_begin = "// JOBS_PROPERTY_DSL_IMPLEMENTATION_AUTOGEN_BEGIN #{owner}"
    marker_end = "// JOBS_PROPERTY_DSL_IMPLEMENTATION_AUTOGEN_END #{owner}"
    missing_methods = methods.sort.uniq.reject { |method| source.include?(method.lines.first.strip) }
    next if missing_methods.empty?
    if source.include?(marker_begin)
      insertion = source.index(marker_end, source.index(marker_begin))
      edits_by_path[path] << [insertion, insertion, "#{missing_methods.join("\n\n")}\n"]
    else
      section = "#{marker_begin}\n#{missing_methods.join("\n\n")}\n#{marker_end}\n"
      edits_by_path[path] << [region.closing, region.closing, section]
    end
  end
end

edits_by_path.each do |path, edits|
  source = sources.fetch(path).dup
  edits.sort_by(&:first).reverse_each { |start_offset, end_offset, replacement| source[start_offset...end_offset] = replacement }
  File.binwrite(path, source)
end

local_declarations = Hash.new { |hash, path| hash[path] = Hash.new { |owners, owner| owners[owner] = [] } }
local_implementations = Hash.new { |hash, path| hash[path] = Hash.new { |owners, owner| owners[owner] = [] } }
local_category_plans.each do |owner, property, selector, type, name, callers, is_class_property|
  setter = "set#{property[0].upcase}#{property[1..]}"
  method_sign = is_class_property ? "+" : "-"
  block_return_type = is_class_property ? "Class" : "__kindof #{owner} *"
  callers.each do |caller|
    local_declarations[caller][owner] << "#{method_sign}(#{name} _Nonnull)#{selector};"
    local_declarations[caller][owner] << "#{method_sign}(void)#{setter}:#{method_parameter_declaration(type)};"
  end
  implementation_path = callers.first
  local_implementations[implementation_path][owner] << <<~OBJC.rstrip
    #{method_sign}(#{name} _Nonnull)#{selector}{
        @jobs_weakify(self)
        return ^#{block_return_type} _Nullable(#{argument_declaration(type)}){
            @jobs_strongify(self)
            [self #{setter}:data];
            return self;
        };
    }
  OBJC
end

(local_declarations.keys | local_implementations.keys).each do |path|
  source = File.binread(path)
  edits = []
  local_declarations[path].each do |owner, lines|
    begin_marker = "// JOBS_LOCAL_PROPERTY_DSL_DECLARATION_AUTOGEN_BEGIN #{owner}"
    end_marker = "// JOBS_LOCAL_PROPERTY_DSL_DECLARATION_AUTOGEN_END #{owner}"
    category = "JobsLocalPropertyDSLAutogen_#{Digest::SHA1.hexdigest(path)[0, 10]}"
    retained = existing_section_lines(source, begin_marker, end_marker)
    section = ([begin_marker, "@interface #{owner} (#{category})"] +
      (retained.reject { |line| line.start_with?("@interface", "@end") } + lines).sort.uniq +
      ["@end", end_marker, ""]).join("\n")
    pattern = /#{Regexp.escape(begin_marker)}.*?#{Regexp.escape(end_marker)}\n?/m
    if (match = source.match(pattern))
      edits << [match.begin(0), match.end(0), section]
    else
      insertion = source.index(/^@implementation\b/) || source.bytesize
      edits << [insertion, insertion, "#{section}\n"]
    end
  end
  local_implementations[path].each do |owner, methods|
    begin_marker = "// JOBS_LOCAL_PROPERTY_DSL_IMPLEMENTATION_AUTOGEN_BEGIN #{owner}"
    end_marker = "// JOBS_LOCAL_PROPERTY_DSL_IMPLEMENTATION_AUTOGEN_END #{owner}"
    category = "JobsLocalPropertyDSLAutogen_#{Digest::SHA1.hexdigest(path)[0, 10]}"
    retained = existing_section_lines(source, begin_marker, end_marker)
    retained_source = retained.reject { |line| line.start_with?("@implementation", "@end") }.join("\n")
    method_source = (methods + [retained_source]).reject(&:empty?).sort.uniq.join("\n\n")
    section = [begin_marker, "@implementation #{owner} (#{category})", method_source, "@end", end_marker, ""].join("\n")
    pattern = /#{Regexp.escape(begin_marker)}.*?#{Regexp.escape(end_marker)}\n?/m
    if (match = source.match(pattern))
      edits << [match.begin(0), match.end(0), section]
    else
      edits << [source.bytesize, source.bytesize, "\n#{section}"]
    end
  end
  updated = source.dup
  edits.sort_by(&:first).reverse_each { |start_offset, end_offset, replacement| updated[start_offset...end_offset] = replacement }
  File.binwrite(path, updated)
end

enum_map = enum_declarations(paths + type_header_paths)
string_typedef_map = string_typedef_declarations(paths + type_header_paths)
forward_lines = Set.new
generated_typedefs.each_value do |_name, return_type, parameter|
  if (return_class = return_type[/\b([A-Za-z_]\w*)\s*\*\z/, 1])
    forward_lines << "@class #{return_class};"
  end
  [return_type, parameter].each do |type|
    type.scan(/\b(?:id|NSObject)\s*<\s*([A-Za-z_]\w*)\s*>/) { |match| forward_lines << "@protocol #{match.first};" }
    type.scan(/\b[A-Za-z_]\w*\b/) do |token|
      forward_lines << enum_map[token] if enum_map.key?(token)
      forward_lines << string_typedef_map[token] if string_typedef_map.key?(token)
    end
    type.scan(/\b([A-Z][A-Za-z0-9_]*)\s*\*/) { |match| forward_lines << "@class #{match.first};" }
    type.scan(/\b([A-Z][A-Za-z0-9_]*)\s*</) { |match| forward_lines << "@class #{match.first};" }
  end
end
forward_lines.delete(nil)
typedef_lines = generated_typedefs.values.map do |name, return_type, parameter|
  "typedef #{nullable_return(return_type)}(^#{name})(#{argument_declaration(parameter)});"
end

options[:forward_headers].each do |path|
  source = File.binread(path)
  lines = existing_section_lines(source, FORWARD_BEGIN, FORWARD_END) + forward_lines.to_a
  outside_generated_section = source.sub(/#{Regexp.escape(FORWARD_BEGIN)}.*?#{Regexp.escape(FORWARD_END)}/m, "")
  existing_enum_names = outside_generated_section.scan(/typedef\s+NS_(?:ENUM|OPTIONS)\s*\(\s*[^,]+,\s*([A-Za-z_]\w*)\s*\)/).flatten.to_set
  lines.reject! do |line|
    line == "@class ;" ||
      (line.match?(/\Atypedef\s+NS_(?:ENUM|OPTIONS)\b/) && existing_enum_names.include?(line[/,\s*([A-Za-z_]\w*)\s*\)\s*;/, 1]))
  end
  File.binwrite(path, replace_generated_section(source, FORWARD_BEGIN, FORWARD_END, lines))
end
options[:return_headers].each do |path|
  source = File.binread(path)
  lines = existing_section_lines(source, TYPEDEF_BEGIN, TYPEDEF_END) + typedef_lines
  File.binwrite(path, replace_generated_section(source, TYPEDEF_BEGIN, TYPEDEF_END, lines))
end
