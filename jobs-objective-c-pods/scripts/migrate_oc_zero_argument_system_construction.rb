#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
require_relative "jobs_oc_ownership"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData generated
].freeze
EXCLUDED_COMPONENT_FRAGMENTS = %w[
  Manual_Add_ThirdParty GeneratedPluginRegistrant Il2CppOutputProject
].freeze
FACTORY_COMPONENTS = %w[
  JobsMakes@Pods JobsOCDSL@Pods
].freeze
FACTORIES = {
  "UIImage" => "jobsMakeImage",
  "NSDateComponents" => "jobsMakeDateComponents",
  "NSDateFormatter" => "jobsMakeDateFormatter",
  "UIBezierPath" => "jobsMakeBezierPath",
  "CABasicAnimation" => "jobsMakeCABasicAnimation",
  "CAEmitterLayer" => "jobsMakeCAEmitterLayer",
  "CAShapeLayer" => "jobsMakeCAShapeLayer",
  "CALayer" => "jobsMakeCALayer",
  "CAGradientLayer" => "jobsMakeCAGradientLayer",
  "CATransition" => "jobsMakeCATransition",
  "CAKeyframeAnimation" => "jobsMakeCAKeyframeAnimation",
  "UITapGestureRecognizer" => "jobsMakeTapGesture",
  "UILongPressGestureRecognizer" => "jobsMakeLongPressGesture",
  "UISwipeGestureRecognizer" => "jobsMakeSwipeGesture",
  "UIPanGestureRecognizer" => "jobsMakePanGesture",
  "UIPinchGestureRecognizer" => "jobsMakePinchGesture",
  "UIRotationGestureRecognizer" => "jobsMakeRotationGesture",
  "UIScreenEdgePanGestureRecognizer" => "jobsMakeScreenEdgePanGestureRecognizer",
  "UIImageView" => "jobsMakeImageView",
  "UITextView" => "jobsMakeTextView",
  "UITextField" => "jobsMakeTextField",
  "UIWindow" => "jobsMakeWindow",
  "UIView" => "jobsMakeView",
  "MFMessageComposeViewController" => "jobsMakeMFMessageComposeVC",
  "MFMailComposeViewController" => "jobsMakeMFMailComposeVC",
  "UILabel" => "jobsMakeLabel",
  "UISlider" => "jobsMakeSlider",
  "UISearchBar" => "jobsMakeUISearchBar",
  "UINavigationBarAppearance" => "jobsMakeNavigationBarAppearance",
  "UITabBarAppearance" => "jobsMakeTabBarAppearance",
  "UINavigationBar" => "jobsMakeNavigationBar",
  "UIRefreshControl" => "jobsMakeRefreshControl",
  "PDFView" => "jobsMakePDFView",
  "UIPageControl" => "jobsMakePageControl",
  "UIStackView" => "jobsMakeStackView",
  "CAEmitterCell" => "jobsMakeCAEmitterCell",
  "WKWebView" => "jobsMakeWKWebView",
  "UISwitch" => "jobsMakeSwitch",
  "UIProgressView" => "jobsMakeProgressView",
  "UIScrollView" => "jobsMakeScrollView",
  "UIImagePickerController" => "jobsMakeImagePickerController",
  "WKUserContentController" => "jobsMakeUserContentController",
  "WKWebViewConfiguration" => "jobsMakeWebViewConfiguration",
  "PHFetchOptions" => "jobsMakePHFetchOptions",
  "PHVideoRequestOptions" => "jobsMakePHVideoRequestOptions",
  "PHImageManager" => "jobsMakePHImageManager",
  "PHImageRequestOptions" => "jobsMakePHImageRequestOptions",
  "NEVPNProtocolIKEv2" => "jobsMakeNEVPNProtocolIKEv2",
  "NSShadow" => "jobsMakeShadow",
  "UITabBarItem" => "jobsMakeTabBarItem",
  "UINavigationItem" => "jobsMakeNavigationItem",
  "NSMutableData" => "jobsMakeMutData",
  "NSMutableIndexSet" => "jobsMakeMutIndexSet",
  "NSMutableDictionary" => "jobsMakeMutDic",
  "NSMutableString" => "jobsMakeMutString",
  "UNMutableNotificationContent" => "jobsMakeUNMutableNotificationContent",
  "JSContext" => "jobsMakeJSContext",
  "NSLock" => "jobsMakeLock"
}.freeze

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) ||
      EXCLUDED_COMPONENT_FRAGMENTS.any? { |fragment| component.include?(fragment) }
  end
end

def factory_layer?(path)
  path.each_filename.any? { |component| FACTORY_COMPONENTS.include?(component) } ||
    path.basename.to_s == "JobsMakes.h" || path.basename.to_s.include?("+DSL")
end

def source_files(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{h,m,mm}"))
  end.uniq.reject { |path| excluded?(Pathname(path)) }.sort
end

def mask_comments_and_literals(source)
  masked = source.dup
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
          masked.setbyte(index, 32) unless source.getbyte(index) == 10
          index += 1
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

def jobs_makes_visible?(path, source)
  return true if source.match?(/#[ \t]*(?:import|include)[ \t]*[<\"][^>\"]*JobsMakes(?:\.h)?[>\"]/) 
  return true if source.match?(/\bjobsMake[A-Z][A-Za-z0-9_]*\s*\(/)
  path.include?("/JobsOCBaseConfigDemo/") && !path.include?("/JobsOCBaseConfigDemo/JobsOCDSL/")
end

options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: migrate_oc_zero_argument_system_construction.rb [--apply] PATH..."
  parser.on("--apply", "Rewrite proven zero-argument constructors") { options[:apply] = true }
end.parse!
roots = ARGV.empty? ? ["."] : ARGV

changed = []
replacements = 0
skipped_visibility = 0
source_files(roots).each do |path|
  pathname = Pathname(path)
  next if factory_layer?(pathname)
  source = File.binread(path)
  utf8_source = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8_source.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, utf8_source)
  masked = mask_comments_and_literals(source)
  edits = []
  patterns = [
    /\b([A-Z][A-Za-z0-9_]*)\s*\.\s*new\b/,
    /\[\s*([A-Z][A-Za-z0-9_]*)\s+new\s*\]/,
    /\b([A-Z][A-Za-z0-9_]*)\s*\.\s*alloc\s*\.\s*init\b/,
    /\[\s*([A-Z][A-Za-z0-9_]*)\s*\.\s*alloc\s+init\s*\]/,
    /\[\s*\[\s*([A-Z][A-Za-z0-9_]*)\s+alloc\s*\]\s+init\s*\]/
  ]
  patterns.each do |pattern|
    masked.to_enum(:scan, pattern).each do
      match = Regexp.last_match
      type = match[1]
      factory = FACTORIES[type]
      next unless factory
      unless jobs_makes_visible?(path, utf8_source)
        skipped_visibility += 1
        next
      end
      next if edits.any? { |start_offset, end_offset, _| match.begin(0) < end_offset && match.end(0) > start_offset }
      edits << [match.begin(0), match.end(0), "#{factory}(^(#{type} *object){})"]
    end
  end
  masked.to_enum(:scan, /\bjobsMakeImage\s*\(\s*\)/).each do
    match = Regexp.last_match
    edits << [match.begin(0), match.end(0), "jobsMakeImage(^(UIImage *object){})"]
  end
  next if edits.empty?
  edits.sort_by!(&:first)
  changed << path
  replacements += edits.length
  puts [options[:apply] ? "updated" : "candidate", path, edits.length].join("\t")
  next unless options[:apply]
  updated = source.dup
  edits.reverse_each { |start_offset, end_offset, replacement| updated[start_offset...end_offset] = replacement }
  File.binwrite(path, updated)
end

puts "changed_files=#{changed.length} replacements=#{replacements} skipped_visibility=#{skipped_visibility} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
