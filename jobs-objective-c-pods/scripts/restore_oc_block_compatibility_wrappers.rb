#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

WRAPPERS = {
  "ASCIIEncoding" => ["jobsASCIIEncoding", "NSData *"],
  "alternateQuotationBeginDelimiter" => ["jobsAlternateQuotationBeginDelimiter", "NSString *"],
  "alternateQuotationEndDelimiter" => ["jobsAlternateQuotationEndDelimiter", "NSString *"],
  "UTF8Encoding" => ["jobsUTF8Encoding", "NSData *"],
  "appDisplayName" => ["jobsAppDisplayName", "NSString *"],
  "areaID" => ["jobsAreaID", "NSString *"],
  "BaseUrl" => ["jobsBaseUrl", "NSString *"],
  "bundlePath" => ["jobsBundlePath", "NSString *"],
  "byHttp" => ["jobsByHttp", "NSString *"],
  "byHttps" => ["jobsByHttps", "NSString *"],
  "cor" => ["jobsCor", "UIColor *"],
  "collationIdentifier" => ["jobsCollationIdentifier", "NSString *"],
  "collatorIdentifier" => ["jobsCollatorIdentifier", "NSString *"],
  "countryCode" => ["jobsCountryCode", "NSString *"],
  "currencyCode" => ["jobsCurrencyCode", "NSString *"],
  "currencySymbol" => ["jobsCurrencySymbol", "NSString *"],
  "currentDevice" => ["jobsCurrentDevice", "UIDevice *"],
  "currentLocale" => ["jobsCurrentLocale", "NSLocale *"],
  "decimalSeparator" => ["jobsDecimalSeparator", "NSString *"],
  "image" => ["jobsImage", "UIImage *"],
  "imageURLPlus" => ["jobsImageURLPlus", nil],
  "isSimulator" => ["jobsIsSimulator", "BOOL"],
  "jobsUrl" => ["jobsURL", "NSURL *"],
  "groupingSeparator" => ["jobsGroupingSeparator", "NSString *"],
  "languageCode" => ["jobsLanguageCode", "NSString *"],
  "mainBundle" => ["jobsMainBundle", "NSBundle *"],
  "measurementSystem" => ["jobsMeasurementSystem", "NSString *"],
  "modelContainerPropertyGenericClass" => ["jobsModelContainerPropertyGenericClass", "NSDictionary *"],
  "modelCustomPropertyMapper" => ["jobsModelCustomPropertyMapper", "NSDictionary *"],
  "mj_ignoredPropertyNames" => ["jobsMJIgnoredPropertyNames", "NSArray *"],
  "mj_objectClassInArray" => ["jobsMJObjectClassInArray", "NSDictionary *"],
  "mj_replacedKeyFromPropertyName" => ["jobsMJReplacedKeyFromPropertyName", "NSDictionary *"],
  "pathForResourceWithFullName" => ["jobsPathForResourceWithFullName", "NSString *"],
  "platform" => ["jobsPlatform", "NSString *"],
  "platformIDStr" => ["jobsPlatformIDStr", "NSString *"],
  "platformNameStr" => ["jobsPlatformNameStr", "NSString *"],
  "pureString" => ["jobsPureString", "NSString *"],
  "quotationBeginDelimiter" => ["jobsQuotationBeginDelimiter", "NSString *"],
  "quotationEndDelimiter" => ["jobsQuotationEndDelimiter", "NSString *"],
  "readUserInfo" => ["jobsCurrentUserInfo", "JobsUserModel *"],
  "removeDecimalPoint" => ["jobsRemoveDecimalPoint", "NSString *"],
  "removeEqualMark" => ["jobsRemoveEqualMark", "NSString *"],
  "removeNewLineMark" => ["jobsRemoveNewLineMark", "NSString *"],
  "removeRetMark" => ["jobsRemoveRetMark", "NSString *"],
  "removeTableMark" => ["jobsRemoveTableMark", "NSString *"],
  "simulatorModel" => ["jobsSimulatorModel", "NSString *"],
  "scriptCode" => ["jobsScriptCode", "NSString *"],
  "shouldAutorotate" => ["jobsShouldAutorotate", "BOOL"],
  "stringByUTF8Encoding" => ["jobsStringByUTF8Encoding", "NSString *"],
  "titleForNormalState" => ["jobsTitleForNormalState", "NSString *"],
  "URLRequest" => ["jobsURLRequest", "NSMutableURLRequest *"],
  "urlProtect" => ["jobsURLProtect", "NSString *"],
  "variantCode" => ["jobsVariantCode", "NSString *"],
}.freeze

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) || component.include?("Manual_Add_ThirdParty")
  end
end

def source_files(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{h,m,mm}"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end


def matching_brace(source, opening)
  depth = 0
  state = :code
  index = opening
  while index < source.bytesize
    current = source.getbyte(index)
    following = index + 1 < source.bytesize ? source.getbyte(index + 1) : nil
    case state
    when :code
      if current == 47 && following == 47
        state = :line_comment
        index += 2
        next
      elsif current == 47 && following == 42
        state = :block_comment
        index += 2
        next
      elsif current == 34
        state = :string
      elsif current == 39
        state = :character
      elsif current == 123
        depth += 1
      elsif current == 125
        depth -= 1
        return index if depth.zero?
      end
    when :line_comment
      state = :code if current == 10
    when :block_comment
      if current == 42 && following == 47
        state = :code
        index += 2
        next
      end
    when :string, :character
      terminal = state == :string ? 34 : 39
      if current == 92
        index += 2
        next
      elsif current == terminal
        state = :code
      end
    end
    index += 1
  end
  nil
end

def original_return_type(source, selector, facade, configured)
  return configured if configured

  facade_type = source[/^[ \t]*-[ \t]*\(([^)]*Block[^)]*)\)[ \t]*#{Regexp.escape(facade)}\b/m, 1]
  facade_type&.include?("URL") ? "NSURL *" : "NSString *"
end

def implementation_class_at(source, offset)
  current = nil
  source[0...offset].to_enum(:scan, /@implementation\s+([A-Za-z_]\w*)|@end\b/).each do
    match = Regexp.last_match
    current = match[1] || nil
  end
  current
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: restore_oc_block_compatibility_wrappers.rb [--apply] PATH..."
  parser.on("--apply", "Restore compatibility selectors and write edits") { options[:apply] = true }
end.parse!

roots = ARGV.empty? ? ["."] : ARGV
changed = []

source_files(roots).each do |path|
  source = File.binread(path)
  next unless source.dup.force_encoding(Encoding::UTF_8).valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  original = source.dup
  WRAPPERS.each do |selector, (facade, configured_type)|
    original_pattern = /^[ \t]*([+-])[ \t]*\(([^)]*Block[^)]*)\)[ \t]*#{Regexp.escape(selector)}\b/m
    if File.extname(path) == ".h"
      source.gsub!(/^([ \t]*)([+-])[ \t]*\(([^)]*Block[^)]*)\)[ \t]*#{Regexp.escape(selector)}[ \t]*;/) do
        return_type = original_return_type(source, selector, facade, configured_type)
        next Regexp.last_match(0) unless return_type

        indent = Regexp.last_match(1)
        method_kind = Regexp.last_match(2)
        block_type = Regexp.last_match(3)
        "#{indent}#{method_kind}(#{return_type})#{selector};\n#{indent}#{method_kind}(#{block_type})#{facade};"
      end
      next
    end

    while (original_match = source.match(original_pattern))
      return_type = original_return_type(source, selector, facade, configured_type)
      break unless return_type

      signature = source[original_match.begin(0)...original_match.end(0)]
      renamed_signature = signature.sub(/#{Regexp.escape(selector)}(?=\s*\z)/, facade)
      implementation_class = implementation_class_at(source, original_match.begin(0))
      break unless implementation_class

      block_type = original_match[2].gsub(/\b_(?:Nonnull|Nullable)\b/, "").gsub(/\s+/, " ").strip
      lookup = original_match[1] == "+" ? "JobsBlockClassMethodIMP" : "JobsBlockInstanceMethodIMP"
      facade_dispatch = "((#{block_type} (*)(__typeof__(self), SEL))#{lookup}(#{implementation_class}.class, @selector(#{facade})))" \
                        "(self, @selector(#{facade}))"
      wrapper = "#{original_match[1]}(#{return_type})#{selector}{\n    return (#{facade_dispatch})();\n}\n\n"
      source[original_match.begin(0)...original_match.end(0)] = "#{wrapper}#{renamed_signature}"
    end
  end

  next if source == original

  File.binwrite(path, source) if options[:apply]
  changed << path
  puts [options[:apply] ? "updated" : "would-update", path].join("\t")
end

warn "files=#{changed.length} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
