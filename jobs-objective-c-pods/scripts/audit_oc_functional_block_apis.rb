#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"
require "set"

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
OBJC_METHOD_FAMILIES = /\A(?:init|new|alloc|copy|mutableCopy)(?:\z|[A-Z_:])/.freeze
FIXED_RUNTIME_SELECTORS = Set.new(%w[
  .cxx_destruct
  class
  debugDescription
  dealloc
  description
  doesNotRecognizeSelector:
  forwardInvocation:
  forwardingTargetForSelector:
  hash
  initialize
  instanceMethodSignatureForSelector:
  isEqual:
  isKindOfClass:
  isMemberOfClass:
  isProxy
  destroySingleton
  getInterfaceOrientation
  getView
  jobsGetCurrentViewController
  jobsGetCurrentViewControllerWithNavCtrl
  load
  methodSignatureForSelector:
  resolveClassMethod:
  resolveInstanceMethod:
  respondsToSelector:
  sharedManager
  teardownAppStateMonitor
  mjFooterDefaultConfig
  mjHeaderDefaultConfig
  conformsToProtocol:
  superclass
]).freeze
COMPATIBILITY_WRAPPER_SELECTORS = Set.new(%w[
  webView
  normalBgImageURL
  normalBgImageURLString
  normalImageURL
  normalImageURLString
  modelContainerPropertyGenericClass
  modelCustomPropertyMapper
  activityType
  horizontalLayout
  verticalLayout
  timeFormatter
  getCurrentViewController
  currentDate
  CellHeight
  CellWidth
  appDisplayName
  areaID
  ASCIIEncoding
  alternateQuotationBeginDelimiter
  alternateQuotationEndDelimiter
  BaseUrl
  bundlePath
  byHttp
  byHttps
  collationIdentifier
  collatorIdentifier
  cor
  countryCode
  currencyCode
  currencySymbol
  decimalSeparator
  groupingSeparator
  counter
  headerHeight
  image
  imageURLPlus
  indicatorSize
  jobsUrl
  jobsSliderValueChangedEventBlock:
  jobsBtnClickEventBlock:
  gestureActionBy:
  GestureActionBy:
  languageCode
  measurementSystem
  mj_ignoredPropertyNames
  mj_objectClassInArray
  mj_replacedKeyFromPropertyName
  pageTitle
  pathForResourceWithFullName
  platform
  platformIDStr
  platformNameStr
  pureString
  quotationBeginDelimiter
  quotationEndDelimiter
  readUserInfo
  removeDecimalPoint
  removeEqualMark
  removeNewLineMark
  removeRetMark
  removeTableMark
  rootViewController
  scriptCode
  shouldAutorotate
  simulatorModel
  stringByUTF8Encoding
  topViewController
  tr
  securityModelBtn
  sound
  textLab
  titleForNormalState
  URLRequest
  urlProtect
  UTF8Encoding
  variantCode
]).freeze
SYSTEM_CALLBACK_PATTERNS = [
  /\AanimateTransition:\z/,
  /\AanimationControllerForDismissedController:\z/,
  /\AcanBecomeFirstResponder\z/,
  /\AchildViewControllerForStatusBarStyle\z/,
  /\AcollectionViewContentSize\z/,
  /\AcontainerViewWillLayoutSubviews\z/,
  /\AdismissalTransitionWillBegin\z/,
  /\AframeOfPresentedViewInContainerView\z/,
  /\ApresentationTransitionWillBegin\z/,
  /\ApresentedView\z/,
  /\AshouldRemovePresentersView\z/,
  /\Aapplication:/,
  /\AcollectionView:/,
  /\A(?:draw|border)Rect:/,
  /\AborderRectForBounds:/,
  /\AdidEnterVisibleState\z/,
  /\AdidLoad\z/,
  /\AdrawParametersForAsyncLayer:/,
  /\AdrawPlaceholderInRect:/,
  /\AdrawTextInRect:/,
  /\AencodeWithCoder:/,
  /\AgestureRecognizer/,
  /\AlayoutAttributesForElementsInRect:/,
  /\AlayoutAttributesForItemAtIndexPath:/,
  /\AlayoutSpecThatFits:/,
  /\AlayoutSubviews\z/,
  /\AlayoutIfNeeded\z/,
  /\AloadView\z/,
  /\Aload\z/,
  /\AnavigationController:/,
  /\AnumberOfSectionsIn(?:CollectionView|TableView):/,
  /\AobserveValueForKeyPath:/,
  /\AprepareForReuse\z/,
  /\AprepareLayout\z/,
  /\Apreferred(?:InterfaceOrientationForPresentation|StatusBarStyle)\z/,
  /\Arequest(?:Argument|Method|Url)\z/,
  /\AjsonValidator\z/,
  /\AcacheTimeInSeconds\z/,
  /\Ascene:/,
  /\AsearchBar/,
  /\AscrollView/,
  /\AsupportedInterfaceOrientations\z/,
  /\AsupportsSecureCoding\z/,
  /\AprefersStatusBarHidden\z/,
  /\AtableView:/,
  /\AshouldBatchFetchForTableNode:/,
  /\A(?:setUp|tearDown|test[A-Za-z_]\w*|runsForEachTargetApplicationUIConfiguration)\z/,
  /\AtextFieldShould/,
  /\AtextView/,
  /\A(?:text|editing|placeholder|clearButton|leftView|rightView)RectForBounds:/,
  /\Atouches(?:Began|Cancelled|Ended|Moved):/,
  /\AtransitionDuration:/,
  /\AtraitCollectionDidChange:/,
  /\AURLSession:/,
  /\AviewDid/,
  /\AviewSafeAreaInsetsDidChange\z/,
  /\AviewWill/,
].freeze
BLOCK_TYPE_NAMES = Set.new

MethodInfo = Struct.new(
  :path,
  :line,
  :context,
  :kind,
  :return_type,
  :selector,
  :parameter_count,
  :signature,
  keyword_init: true
)

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) ||
      EXCLUDED_COMPONENT_FRAGMENTS.any? { |fragment| component.include?(fragment) }
  end
end

def source_files(roots)
  explicit_files = roots.filter_map do |root|
    expanded = File.expand_path(root)
    expanded if File.file?(expanded)
  end.to_set
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    if File.file?(expanded)
      [expanded]
    else
      Dir.glob(File.join(expanded, "**", "*.{h,m,mm}"))
    end
  end.uniq.reject { |path| excluded?(Pathname(path)) && !explicit_files.include?(path) }.sort
end

def contract_source_files(roots)
  roots.flat_map do |root|
    expanded = File.expand_path(root)
    if File.file?(expanded)
      [expanded]
    else
      Dir.glob(File.join(expanded, "**", "*.h"))
    end
  end.uniq.reject do |path|
    Pathname(path).each_filename.any? { |component| %w[.git build DerivedData].include?(component) }
  end.sort
end


def explicit_third_party_path?(path)
  path.each_filename.any? do |component|
    %w[ManualByOCPods@Pods PodsManual].include?(component) ||
      component.include?("Manual_Add_ThirdParty")
  end
end

def mask_comments_and_literals(source)
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
        if index < bytes.length
          masked.setbyte(index, 32) unless bytes[index] == "\n"
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

def mask_preprocessor_directives(masked)
  bytes = masked.dup
  offset = 0
  continued = false
  bytes.lines.each do |line|
    directive = continued || line.match?(/\A[ \t]*#/)
    if directive
      line.bytes.each_with_index do |byte, index|
        bytes.setbyte(offset + index, 32) unless byte == 10 || byte == 13
      end
      continued = line.sub(/[\r\n]+\z/, "").end_with?("\\")
    else
      continued = false
    end
    offset += line.bytesize
  end
  bytes
end

def matching_parenthesis(source, opening)
  depth = 0
  cursor = opening
  while cursor < source.length
    case source.getbyte(cursor)
    when 40
      depth += 1
    when 41
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
  while cursor < source.length
    case source.getbyte(cursor)
    when 40
      parentheses += 1
    when 41
      parentheses -= 1
    when 91
      brackets += 1
    when 93
      brackets -= 1
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
      tokens << [match.begin(0), :open, match[2]]
    else
      tokens << [match.begin(0), :close, nil]
    end
  end

  intervals = []
  stack = []
  tokens.each do |offset, action, name|
    if action == :open
      stack << [offset, name]
    elsif stack.any?
      opening, context = stack.pop
      intervals << [opening, offset, context]
    end
  end
  stack.each { |opening, context| intervals << [opening, masked.length, context] }
  intervals.sort_by(&:first)
end

def context_at(intervals, offset)
  interval = intervals.reverse.find { |opening, closing, _| opening <= offset && offset <= closing }
  interval&.last || "<global>"
end

def property_accessors(source, masked, intervals)
  accessors = Hash.new { |hash, key| hash[key] = Set.new }
  patterns = [
    /@property\b.*?;/m,
    /\bProp(?:_[A-Za-z_]\w*)?\s*\([^)]*\)\s*.*?;/m,
  ]

  patterns.each do |pattern|
    masked.to_enum(:scan, pattern).each do
      match = Regexp.last_match
      statement = source[match.begin(0)...match.end(0)]
      declaration = statement.gsub(/\bAPI_[A-Z_]+\s*\([^;]*\)/m, " ")
      name = declaration[/([A-Za-z_]\w*)\s*;\s*\z/m, 1]
      next unless name

      context = context_at(intervals, match.begin(0))
      getter = statement[/\bgetter\s*=\s*([A-Za-z_]\w*)/, 1] || name
      setter = statement[/\bsetter\s*=\s*([A-Za-z_]\w*:)/, 1]
      setter ||= "set#{name[0].upcase}#{name[1..]}:"
      accessors[context] << getter
      # A readonly declaration can still have an explicit private/custom setter.
      # If setXxx: exists, it remains property ABI and must not be removed as a
      # redundant functional wrapper.
      accessors[context] << setter
    end
  end

  masked.to_enum(:scan, /@(synthesize|dynamic)\s+([^;]+);/m).each do
    match = Regexp.last_match
    context = context_at(intervals, match.begin(0))
    match[2].split(",").each do |entry|
      name = entry.split("=", 2).first.strip[/\A([A-Za-z_]\w*)/, 1]
      next unless name

      accessors[context] << name
      accessors[context] << "set#{name[0].upcase}#{name[1..]}:"
    end
  end
  accessors
end

def context_relationships(masked)
  parents = Hash.new { |hash, key| hash[key] = Set.new }
  generic_parameters = /(?:\s*<\s*(?:__covariant|__contravariant)\b[^>]*>)?/
  pattern = /@(interface|protocol)\s+([A-Za-z_]\w*)(?:\s*\([^)]*\))?#{generic_parameters}\s*(?::\s*([A-Za-z_]\w*))?\s*(?:<([^>]+)>)?/
  masked.scan(pattern) do |_kind, name, superclass, protocols|
    parents[name] << superclass if superclass
    protocols.to_s.scan(/[A-Za-z_]\w*/).each { |protocol| parents[name] << protocol }
  end
  parents
end

def referenced_selectors(source)
  selectors = Set.new
  contract_source = source.lines.reject do |line|
    line.include?("JobsBlockInstanceMethodIMP") || line.include?("JobsBlockClassMethodIMP")
  end.join
  contract_source.scan(/@selector\s*\(\s*([A-Za-z_]\w*(?::[A-Za-z_]\w*)*:?)\s*\)/) do |match|
    selectors << match.first
  end
  contract_source.scan(/NSSelectorFromString\s*\(\s*@"([A-Za-z_]\w*(?::[A-Za-z_]\w*)*:?)"\s*\)/) do |match|
    selectors << match.first
  end
  selectors
end

def parse_methods(path, source, masked, intervals)
  methods = []
  offset = 0
  pattern = /^[ \t]*([+-])[ \t]*\(/m

  while (match = masked.match(pattern, offset))
    opening = masked.index("(", match.begin(0))
    closing = matching_parenthesis(masked, opening)
    break unless closing

    terminator = signature_terminator(masked, closing + 1)
    break unless terminator

    return_type = source[(opening + 1)...closing].strip.gsub(/\s+/, " ")
    signature = source[(closing + 1)...terminator].strip.gsub(/\s+/, " ")
    labels = signature.scan(/\b([A-Za-z_]\w*)\s*:/).flatten
    selector = if labels.empty?
                 signature[/\A([A-Za-z_]\w*)/, 1]
               else
                 "#{labels.join(':')}:"
               end
    if selector
      methods << MethodInfo.new(
        path: path,
        line: source[0...match.begin(0)].count("\n") + 1,
        context: context_at(intervals, match.begin(0)),
        kind: match[1],
        return_type: return_type,
        selector: selector,
        parameter_count: labels.length,
        signature: signature
      )
    end
    offset = terminator + 1
  end
  methods
end

def block_return?(return_type)
  type_name = return_type.gsub(/\b(?:_Nonnull|_Nullable|nonnull|nullable|__kindof)\b/, "")
                         .gsub(/\s+/, "")
  BLOCK_TYPE_NAMES.include?(type_name) ||
    return_type.match?(/\b[A-Za-z_]\w*Blocks?\b/) ||
    return_type.include?("(^")
end

def compatibility_wrapper?(method, block_selectors)
  key = [method.path, method.context, method.kind]
  selectors = block_selectors[key]
  return false unless selectors

  if method.selector.end_with?(":")
    base_selector = method.selector.delete_suffix(":")
    camel_facade = "jobs#{base_selector[0].upcase}#{base_selector[1..]}"
    selectors.include?(base_selector) || selectors.include?(camel_facade) || selectors.include?("#{camel_facade}Block") ||
      (method.selector == "isLogin:" && selectors.include?("jobsCheckLogin"))
  else
    camel_facade = "jobs#{method.selector[0].upcase}#{method.selector[1..]}"
    selectors.include?("jobs_#{method.selector}") || selectors.include?(camel_facade) ||
      selectors.include?("#{camel_facade}Block")
  end
end

def exclusion_reason(method, accessors, selector_references, external_contract_selectors,
                     internal_protocol_selectors, block_selectors, ownership_mismatch_paths)
  return "already-block" if block_return?(method.return_type)
  return "parameter-count" unless method.parameter_count <= 1
  return "ownership-mismatch" if ownership_mismatch_paths.include?(method.path)
  return "compatibility-wrapper" if COMPATIBILITY_WRAPPER_SELECTORS.include?(method.selector)
  return "property-accessor" if accessors[method.context].include?(method.selector)
  return "property-accessor" if method.selector.match?(/\Aset[A-Z_]\w*:\z/)
  return "objc-family" if method.selector.match?(OBJC_METHOD_FAMILIES)
  return "runtime-contract" if FIXED_RUNTIME_SELECTORS.include?(method.selector)
  return "system-callback" if SYSTEM_CALLBACK_PATTERNS.any? { |pattern| method.selector.match?(pattern) }
  return "selector-reference" if selector_references.include?(method.selector)
  return "protocol-contract" if internal_protocol_selectors.include?(method.selector)
  return "external-contract" if external_contract_selectors.include?(method.selector)
  return "ib-action" if method.return_type.include?("IBAction")
  # 旧 selector 只作为系统/协议 ABI 或历史调用面的转发壳存在时，必须保留；
  # 真正的功能内核已经由同类中的 Block getter 承接，不能再把壳层当成待删除候选。
  return "compatibility-wrapper" if compatibility_wrapper?(method, block_selectors)

  nil
end

options = { show_excluded: false, contract_roots: [] }
OptionParser.new do |parser|
  parser.banner = "Usage: audit_oc_functional_block_apis.rb [options] PATH..."
  parser.on("--show-excluded", "Print excluded methods together with the reason") do
    options[:show_excluded] = true
  end
  parser.on("--contract-root PATH", "Headers that define system or third-party selectors; repeatable") do |path|
    options[:contract_roots] << path
  end
end.parse!

roots = ARGV.empty? ? ["."] : ARGV
files = source_files(roots)
all_sources = {}
all_masked = {}
all_intervals = {}
all_accessors = Hash.new { |hash, key| hash[key] = Set.new }
all_context_parents = Hash.new { |hash, key| hash[key] = Set.new }
all_selector_references = Set.new
external_contract_selectors = Set.new

files.each do |path|
  source = File.binread(path)
  utf8_source = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8_source.valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  masked = mask_preprocessor_directives(mask_comments_and_literals(source))
  intervals = context_intervals(masked)
  all_sources[path] = source
  all_masked[path] = masked
  all_intervals[path] = intervals
  property_accessors(source, masked, intervals).each do |context, selectors|
    all_accessors[context].merge(selectors)
  end
  context_relationships(masked).each do |context, parents|
    all_context_parents[context].merge(parents)
  end
  all_selector_references.merge(referenced_selectors(source))
end


contract_source_files(options[:contract_roots]).each do |path|
  source = File.binread(path)
  utf8_source = source.dup.force_encoding(Encoding::UTF_8)
  next unless utf8_source.valid_encoding?
  next if JobsOCOwnership.jobs_owned_file?(path, source) && !explicit_third_party_path?(Pathname(path))

  masked = mask_preprocessor_directives(mask_comments_and_literals(source))
  intervals = context_intervals(masked)
  parse_methods(path, source, masked, intervals).each do |method|
    external_contract_selectors << method.selector
  end
  property_accessors(source, masked, intervals).each_value do |selectors|
    external_contract_selectors.merge(selectors)
  end
end


resolve_accessors = lambda do |context, seen = Set.new|
  return Set.new if seen.include?(context)

  next_seen = seen.dup.add(context)
  inherited = all_context_parents[context].each_with_object(Set.new) do |parent, selectors|
    selectors.merge(resolve_accessors.call(parent, next_seen))
  end
  all_accessors[context].merge(inherited)
end
all_context_parents.keys.each { |context| resolve_accessors.call(context) }

all_sources.each_value do |source|
  source.scan(/typedef\b[^;]*?\(\s*\^\s*([A-Za-z_]\w*)\s*\)\s*\([^;]*?\)\s*[^;]*;/m) do |match|
    BLOCK_TYPE_NAMES << match.first
  end
end

counts = Hash.new(0)
candidate_files = Set.new
methods_by_path = all_sources.to_h do |path, source|
  [path, parse_methods(path, source, all_masked.fetch(path), all_intervals.fetch(path))]
end
methods_by_path.values.flatten.each do |method|
  next unless method.parameter_count.zero?

  getter = method.selector
  next unless getter&.match?(/\A[A-Za-z_]\w*\z/)

  all_accessors[method.context] << "set#{getter[0].upcase}#{getter[1..]}:"
end
protocol_contexts = all_masked.values.flat_map do |masked|
  masked.scan(/@protocol\s+([A-Za-z_]\w*)/).flatten
end.to_set
internal_protocol_selectors = methods_by_path.values.flatten.each_with_object(Set.new) do |method, selectors|
  selectors << method.selector if protocol_contexts.include?(method.context)
end
block_selectors = Hash.new { |hash, key| hash[key] = Set.new }
methods_by_path.each_value do |methods|
  methods.each do |method|
    next unless block_return?(method.return_type)

    block_selectors[[method.path, method.context, method.kind]] << method.selector
  end
end
ownership_mismatch_paths = Set.new
all_sources.each_key do |path|
  next unless File.extname(path) == ".h"

  implementations = %w[.m .mm].map { |extension| path.sub(/\.h\z/, extension) }.select { |candidate| File.file?(candidate) }
  next if implementations.empty?
  next if implementations.any? { |implementation| all_sources.key?(implementation) }

  ownership_mismatch_paths << path
end

methods_by_path.each do |path, methods|
  methods.each do |method|
    reason = exclusion_reason(method, all_accessors, all_selector_references, external_contract_selectors,
                              internal_protocol_selectors, block_selectors, ownership_mismatch_paths)
    counts[reason || "candidate"] += 1
    actionable = reason.nil?
    next if !actionable && !options[:show_excluded]

    candidate_files << path if actionable
    status = reason || "candidate"
    fields = [status, path, method.line, method.context, method.kind, method.selector,
              method.parameter_count, method.return_type, method.signature]
    puts fields.map { |field| field.to_s.dup.force_encoding(Encoding::UTF_8) }.join("\t")
  end
end

summary = counts.sort.map { |name, count| "#{name}=#{count}" }.join(" ")
warn "#{summary} candidate_files=#{candidate_files.length} scanned=#{all_sources.length}"
exit(counts["candidate"].positive? ? 2 : 0)
