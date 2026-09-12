#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
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
LOW_LEVEL_COMPONENTS = %w[
  JobsByUIKit@Pods
  JobsSwiftDSL@Pods
  JobsSwiftBaseDefines@Pods
  JobsTextTools@Pods
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
SYSTEM_PARENTS = {
  "UIResponder" => "NSObject",
  "UIView" => "UIResponder",
  "UIControl" => "UIView",
  "UIButton" => "UIControl",
  "UILabel" => "UIView",
  "UIImageView" => "UIView",
  "UIStackView" => "UIView",
  "UIScrollView" => "UIView",
  "UITableView" => "UIScrollView",
  "UICollectionView" => "UIScrollView",
  "UITextView" => "UIScrollView",
  "UITextField" => "UIControl",
  "UISearchBar" => "UIView",
  "UIPickerView" => "UIView",
  "UIDatePicker" => "UIControl",
  "UISwitch" => "UIControl",
  "UISlider" => "UIControl",
  "UIProgressView" => "UIView",
  "UIPageControl" => "UIControl",
  "UITableViewCell" => "UIView",
  "UICollectionViewCell" => "UIView",
  "UIViewController" => "UIResponder",
  "UINavigationController" => "UIViewController",
  "UITabBarController" => "UIViewController",
  "UIAlertController" => "UIViewController",
  "UIGestureRecognizer" => "NSObject",
  "CALayer" => "NSObject",
  "CAShapeLayer" => "CALayer",
  "CAGradientLayer" => "CALayer",
  "CATextLayer" => "CALayer",
  "CAReplicatorLayer" => "CALayer",
  "AVPlayerLayer" => "CALayer",
  "Formatter" => "NSObject",
  "DateFormatter" => "Formatter",
  "NumberFormatter" => "Formatter",
  "JSONDecoder" => "NSObject",
  "JSONEncoder" => "NSObject"
}.freeze
CELL_CHILD_METHODS = {
  "textLabel" => {
    "text" => "byText",
    "attributedText" => "byAttributedText",
    "font" => "byTitleFont",
    "textColor" => "byTitleCor",
    "textAlignment" => "byTitleTextAlignment",
    "numberOfLines" => "byTitleNumberOfLines"
  },
  "detailTextLabel" => {
    "text" => "byDetailText",
    "attributedText" => "byDetailAttributedText",
    "font" => "byDetailTitleFont",
    "textColor" => "byDetailTitleCor",
    "textAlignment" => "byDetailTitleTextAlignment",
    "numberOfLines" => "byDetailTitleNumberOfLines"
  }
}.freeze
BUTTON_CHILD_METHODS = {
  "titleLabel" => {
    "font" => "byTitleFont",
    "numberOfLines" => "byTitleLines",
    "textAlignment" => "byTitleAlignment",
    "adjustsFontSizeToFitWidth" => "byTitleAdjustsFontSizeToFitWidth",
    "minimumScaleFactor" => "byTitleMinimumScaleFactor"
  }
}.freeze

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) ||
      EXCLUDED_COMPONENT_FRAGMENTS.any? { |fragment| component.include?(fragment) }
  end
end

def low_level?(path)
  path.each_filename.any? { |component| LOW_LEVEL_COMPONENTS.include?(component) }
end

def source_files(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.swift"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end

def dsl_roots(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    if File.basename(expanded).match?(/\AJobs(?:SwiftDSL|ByUIKit)@Pods\z/)
      [expanded]
    else
      Dir.glob(File.join(expanded, "**", "Jobs{SwiftDSL,ByUIKit}@Pods"))
    end
  end.uniq
end

def dsl_registry(roots)
  registry = Hash.new { |hash, key| hash[key] = Set.new }
  dsl_roots(roots).each do |root|
    Dir.glob(File.join(root, "**", "*.swift")).sort.each do |path|
      depth = 0
      extension_type = nil
      extension_depth = nil
      File.readlines(path, encoding: "UTF-8", invalid: :replace, undef: :replace).each do |line|
        if extension_type.nil? && (match = line.match(/^\s*(?:public\s+)?extension\s+([A-Za-z_][A-Za-z0-9_.]*)\b/))
          extension_type = match[1].split(".").last
          extension_depth = depth + line.count("{") - line.count("}")
        elsif extension_type && (match = line.match(/\bfunc\s+(by[A-Z][A-Za-z0-9_]*)\s*\(/))
          registry[extension_type] << match[1]
        end

        depth += line.count("{") - line.count("}")
        if extension_type && depth < extension_depth
          extension_type = nil
          extension_depth = nil
        end
      end
    end
  end
  registry
end

def class_parents(files)
  parents = SYSTEM_PARENTS.dup
  files.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    next unless JobsSwiftOwnership.jobs_owned_file?(path, source)

    source.scan(/\b(?:class|final\s+class|open\s+class|public\s+class)\s+([A-Z][A-Za-z0-9_]*)\s*:\s*([A-Z][A-Za-z0-9_.]*)/) do |child, parent|
      parents[child] = parent.split(".").last
    end
  end
  parents
end

def type_properties(files)
  properties = Hash.new { |hash, key| hash[key] = {} }
  files.each do |path|
    source = File.binread(path).force_encoding(Encoding::UTF_8)
    next unless source.valid_encoding?
    next unless JobsSwiftOwnership.jobs_owned_file?(path, source)

    depth = 0
    scopes = []
    source.each_line do |line|
      if (match = line.match(/^\s*(?:(?:public|open|internal|private|fileprivate|final)\s+)*(?:class|struct)\s+([A-Z][A-Za-z0-9_]*)\b/))
        scopes << [match[1], depth + line.count("{") - line.count("}")]
      elsif (match = line.match(/^\s*(?:(?:public|internal|private|fileprivate)\s+)*extension\s+([A-Z][A-Za-z0-9_]*)\b/))
        scopes << [match[1], depth + line.count("{") - line.count("}")]
      end

      if scopes.any?
        owner = scopes.last.first
        if (match = line.match(/^\s*(?:(?:public|open|internal|private|fileprivate|static|class|lazy|weak|unowned)\s+)*(?:let|var)\s+([a-z_][A-Za-z0-9_]*)\s*:\s*([A-Z][A-Za-z0-9_.]*)\??/))
          properties[owner][match[1]] = match[2].split(".").last
        elsif (match = line.match(/^\s*(?:(?:public|open|internal|private|fileprivate|static|class|lazy|weak|unowned)\s+)*(?:let|var)\s+([a-z_][A-Za-z0-9_]*)\s*=\s*([A-Z][A-Za-z0-9_.]*)\s*\(/))
          properties[owner][match[1]] ||= match[2].split(".").last
        end
      end

      depth += line.count("{") - line.count("}")
      scopes.pop while scopes.any? && depth < scopes.last.last
    end
  end
  properties
end

def symbol_types(source)
  types = {}
  source.scan(/\b(?:let|var)\s+([a-z_][A-Za-z0-9_]*)\s*:\s*(?:weak\s+|unowned\s+)?([A-Z][A-Za-z0-9_.]*)\??/) do |name, type|
    types[name] = type.split(".").last
  end
  source.scan(/\b(?:let|var)\s+([a-z_][A-Za-z0-9_]*)\s*=\s*([A-Z][A-Za-z0-9_.]*)\s*\(/) do |name, type|
    types[name] ||= type.split(".").last
  end
  source.scan(/\b([a-z_][A-Za-z0-9_]*)\s*:\s*(?:inout\s+)?([A-Z][A-Za-z0-9_.]*)\??/) do |name, type|
    types[name] ||= type.split(".").last
  end
  source.scan(/\b(?:let|var)\s+([a-z_][A-Za-z0-9_]*)\s*=\s*[^\n]+\bas\?\s*([A-Z][A-Za-z0-9_.]*)/) do |name, type|
    types[name] = type.split(".").last
  end
  types
end

def ancestors(type, parents)
  result = []
  cursor = type
  visited = Set.new
  while cursor && visited.add?(cursor)
    result << cursor
    cursor = parents[cursor]
  end
  result
end

def method_available?(type, method, registry, parents)
  type && ancestors(type, parents).any? { |candidate| registry[candidate].include?(method) }
end

def receiver_type(receiver, types, parents, properties)
  normalized = receiver.sub(/\Aself\./, "")
  components = normalized.gsub("?.", ".").split(".")
  type = types[components.shift]
  components.each do |component|
    custom_property_type = type && properties[type][component]
    type = custom_property_type || case component
           when "layer"
             ancestors(type, parents).include?("UIView") ? "CALayer" : nil
           when "textLabel", "detailTextLabel"
             ancestors(type, parents).include?("UITableViewCell") ? "UILabel" : nil
           when "titleLabel"
             ancestors(type, parents).include?("UIButton") ? "UILabel" : nil
           when "contentView"
             if ancestors(type, parents).any? { |candidate| %w[UITableViewCell UICollectionViewCell].include?(candidate) }
               "UIView"
             end
           when "imageView"
             ancestors(type, parents).include?("UITableViewCell") ? "UIImageView" : nil
           end
    break unless type
  end
  type
end

def candidate_method(property)
  BOOL_PROPERTY_ALIASES.fetch(property) do
    "by#{property.sub(/\A./) { |letter| letter.upcase }}"
  end
end

def balanced_expression?(expression)
  balances = { "(" => 0, "[" => 0, "{" => 0 }
  pairs = { ")" => "(", "]" => "[", "}" => "{" }
  expression.each_char do |character|
    balances[character] += 1 if balances.key?(character)
    balances[pairs[character]] -= 1 if pairs.key?(character)
  end
  balances.values.all?(&:zero?)
end

def assignment_replacement(line, types, registry, parents, properties)
  match = line.match(/\A(\s*)((?:self\.)?[a-z_][A-Za-z0-9_]*(?:(?:\?\.|\.)[A-Za-z_][A-Za-z0-9_]*)*)\.([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)\s*(.+?)(\s*\/\/.*)?\n?\z/)
  return unless match

  indent, receiver, property, expression, comment = match.captures
  return if receiver == "self"
  return if expression.include?(";")
  return unless balanced_expression?(expression)

  normalized = receiver.gsub("?.", ".")
  components = normalized.sub(/\Aself\./, "").split(".")
  root = components.first
  root_type = types[root]
  method = nil
  output_receiver = receiver

  if components.length == 2 && CELL_CHILD_METHODS.key?(components.last) && ancestors(root_type, parents).include?("UITableViewCell")
    method = CELL_CHILD_METHODS[components.last][property]
    output_receiver = receiver.sub(/(?:\?\.)?\.(?:textLabel|detailTextLabel)\??\z/, "")
  elsif components.length == 2 && BUTTON_CHILD_METHODS.key?(components.last) && ancestors(root_type, parents).include?("UIButton")
    method = BUTTON_CHILD_METHODS[components.last][property]
    output_receiver = receiver.sub(/(?:\?\.)?\.titleLabel\??\z/, "")
  else
    method = candidate_method(property)
    type = receiver_type(receiver, types, parents, properties)
    if components.last == "layer" && ancestors(root_type, parents).include?("UIView") && method_available?(root_type, method, registry, parents)
      output_receiver = receiver.sub(/\.layer\z/, "")
    elsif !method_available?(type, method, registry, parents)
      return
    end
  end
  return unless method
  return unless method_available?(root_type, method, registry, parents) || method_available?(receiver_type(receiver, types, parents, properties), method, registry, parents)

  suffix = comment ? " #{comment.strip}" : ""
  "#{indent}#{output_receiver}.#{method}(#{expression.strip})#{suffix}\n"
end

def chain_adjacent_calls(lines)
  output = []
  index = 0
  while index < lines.length
    match = lines[index].match(/\A(\s*)((?:self\.)?[a-z_][A-Za-z0-9_]*(?:(?:\?\.|\.)[A-Za-z_][A-Za-z0-9_]*)*)\.(by[A-Z][A-Za-z0-9_]*\(.*\))(\s*\/\/.*)?\n\z/)
    unless match && balanced_expression?(match[3])
      output << lines[index]
      index += 1
      next
    end

    indent, receiver = match[1], match[2]
    group = []
    cursor = index
    while cursor < lines.length
      candidate = lines[cursor].match(/\A#{Regexp.escape(indent)}#{Regexp.escape(receiver)}\.(by[A-Z][A-Za-z0-9_]*\(.*\))(\s*\/\/.*)?\n\z/)
      break unless candidate && balanced_expression?(candidate[1])

      group << [candidate[1], candidate[2]]
      cursor += 1
    end

    if group.length < 2
      output << lines[index]
      index += 1
      next
    end

    output << "#{indent}#{receiver}\n"
    group.each do |call, comment|
      suffix = comment ? " #{comment.strip}" : ""
      output << "#{indent}    .#{call}#{suffix}\n"
    end
    index = cursor
  end
  output
end

def ensure_dsl_import(source)
  return source if source.match?(/^import JobsSwiftDSL\s*$/)
  return source if source.match?(/^import JobsByUIKit\s*$/)

  lines = source.lines
  import_indexes = lines.each_index.select { |index| lines[index].match?(/^import\s+[A-Za-z_][A-Za-z0-9_.]*\s*$/) }
  return source if import_indexes.empty?

  last_import = import_indexes.last
  insertion = last_import + 1
  probe = insertion
  probe += 1 while probe < lines.length && lines[probe].strip.empty?
  if probe < lines.length && lines[probe].match?(/^\s*#endif\b/)
    insertion = probe + 1
  end
  insertion += 1 while insertion < lines.length && lines[insertion].strip.empty?
  lines.insert(insertion, "import JobsSwiftDSL\n\n")
  lines.join
end

options = { apply: false }
OptionParser.new do |parser|
  parser.on("--apply") { options[:apply] = true }
end.parse!
roots = ARGV.empty? ? ["."] : ARGV
files = source_files(roots)
registry = dsl_registry(roots)
parents = class_parents(files)
properties = type_properties(files)
changed = []
replacements = 0

files.each do |path|
  source = File.binread(path).force_encoding(Encoding::UTF_8)
  next unless source.valid_encoding?
  next unless JobsSwiftOwnership.jobs_owned_file?(path, source)
  next if low_level?(Pathname(path))

  types = symbol_types(source)
  file_replacements = 0
  rewritten = source.lines.map do |line|
    replacement = assignment_replacement(line, types, registry, parents, properties)
    file_replacements += 1 if replacement
    replacement || line
  end
  rewritten = chain_adjacent_calls(rewritten).join
  rewritten = ensure_dsl_import(rewritten) if file_replacements.positive?
  next if rewritten == source

  changed << path
  replacements += file_replacements
  if options[:apply]
    File.binwrite(path, rewritten)
  else
    puts path
  end
end

puts "changed_files=#{changed.length} assignment_replacements=#{replacements} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
