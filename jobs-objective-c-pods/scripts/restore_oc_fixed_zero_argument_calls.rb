#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"
require "optparse"
require "pathname"
require "set"

EXCLUDED_COMPONENTS = %w[
  .git Pods ManualByOCPods@Pods PodsManual build DerivedData
].freeze

def excluded?(path)
  path.each_filename.any? do |component|
    EXCLUDED_COMPONENTS.include?(component) || component.include?("Manual_Add_ThirdParty")
  end
end


options = { apply: false }
OptionParser.new do |parser|
  parser.banner = "Usage: restore_oc_fixed_zero_argument_calls.rb [--apply] PATH..."
  parser.on("--apply", "Restore fixed zero-argument properties and compatibility façades") { options[:apply] = true }
end.parse!

roots = ARGV.empty? ? ["."] : ARGV
files = roots.flat_map do |root|
  expanded = File.expand_path(root)
  File.file?(expanded) ? [expanded] : Dir.glob(File.join(expanded, "**", "*.{h,m,mm}"))
end.uniq.reject { |path| excluded?(Pathname(path)) }.sort

ordinary_shared_classes = files.select { |path| File.extname(path) == ".h" }.each_with_object(Set.new) do |path, classes|
  source = File.binread(path)
  next unless source.dup.force_encoding(Encoding::UTF_8).valid_encoding?

  source.scan(/@interface\s+([A-Za-z_]\w*)[^\n]*\n(.*?)@end/m) do |class_name, body|
    signature = body.match(/\+\s*\(\s*([^)]*)\)\s*shared\s*;/)
    next unless signature

    return_type = signature[1]
    next if return_type.match?(/\b(?:Jobs|jobs)[A-Za-z_]\w*Blocks?\b/) || return_type.include?("(^")

    classes << class_name
  end
end

changed = 0
files.each do |path|
  source = File.binread(path)
  next unless source.dup.force_encoding(Encoding::UTF_8).valid_encoding? && JobsOCOwnership.jobs_owned_file?(path, source)

  updated = source.dup
  ordinary_shared_classes.each do |class_name|
    updated.gsub!(/\b#{Regexp.escape(class_name)}\s*\.\s*shared\s*\(\s*\)/, "#{class_name}.shared")
  end
  updated.gsub!(/\bUIDevice\s*\.\s*currentDevice\s*\(\s*\)/, "UIDevice.currentDevice")
  updated.gsub!(/\bNSBundle\s*\.\s*mainBundle\s*\(\s*\)/, "NSBundle.mainBundle")
  updated.gsub!(/\bNSLocale\s*\.\s*currentLocale\s*\(\s*\)/, "NSLocale.currentLocale")
  updated.gsub!(/\bNSLocale\s*\.\s*systemLocale\s*\(\s*\)/, "NSLocale.systemLocale")
  updated.gsub!(/\bAVAudioSession\s*\.\s*sharedInstance\s*\(\s*\)/, "AVAudioSession.sharedInstance")
  updated.gsub!(/\b(DDOSLogger|DDTTYLogger)\s*\.\s*sharedInstance\s*\(\s*\)/, '\1.sharedInstance')
  updated.gsub!(/\b(context)\.biometryType\s*\(\s*\)/, '\1.biometryType')
  if path.end_with?("/JobsOCAudioRecorder.m")
    updated.gsub!(/\bself\.(recorder|player)\.(currentTime|stop)\s*\(\s*\)/, 'self.\1.\2')
  end
  if path.end_with?("/JobsOCSplashVC.m")
    updated.gsub!(/\bself\.(mediaTask|player)\.(cancel|pause)\s*\(\s*\)/, 'self.\1.\2')
  end
  updated.gsub!(/\b(JobsThemeCenter|JobsIconfontManager)\s*\.\s*shared\s*\(\s*\)/, '\\1.shared')
  updated.gsub!(/\b(NEVPNManager|IQKeyboardManager|SDWebImageManager|ASIdentifierManager)\s*\.\s*sharedManager\s*\(\s*\)/, '\\1.sharedManager')
  updated.gsub!(/\bJobsRecordPresentedViewController\.sharedManager\b(?!\s*\(\s*\))/, '((JobsRecordPresentedViewController *)JobsRecordPresentedViewController.sharedManager())')
  updated.gsub!(/(?<!\*\))\bJobsOCCrashLogCenter\.sharedManager\s*\(\s*\)/, '((JobsOCCrashLogCenter *)JobsOCCrashLogCenter.sharedManager())')
  updated.gsub!(/(?<!\*\))\bJobsOCKeyboardMgr\.shared\s*\(\s*\)/, '((JobsOCKeyboardMgr *)JobsOCKeyboardMgr.shared())')
  %w[JobsOCAudioRecordingStore JobsOCAudioRecorderEngine JobsOCAudioPlayerEngine].each do |class_name|
    updated.gsub!(/(?<!\*\))\b#{class_name}\.shared\s*\(\s*\)/, "((#{class_name} *)#{class_name}.shared())")
  end
  %w[_JobsOCOpenMailProxy _JobsOCOpenObjectMailProxy].each do |class_name|
    updated.gsub!(/(?<!\*\))\b#{class_name}\.shared\s*\(\s*\)/, "((#{class_name} *)#{class_name}.shared())")
  end
  updated.gsub!(/(?<!\*\))\bJobsOCSplashMediaCache\.shared\s*\(\s*\)/, '((JobsOCSplashMediaCache *)JobsOCSplashMediaCache.shared())')
  updated.gsub!(/(?<!\*\))\bJobsNetworkTrafficMonitor\.shared\s*\(\s*\)/, '((JobsNetworkTrafficMonitor *)JobsNetworkTrafficMonitor.shared())')
  updated.gsub!(/(?<!\*\))\bMyAppTools\.sharedManager\s*\(\s*\)/, '((MyAppTools *)MyAppTools.sharedManager())')
  updated.gsub!(/(?<!\*\))\bNotifiViewFactory\.shared\s*\(\s*\)/, '((NotifiViewFactory *)NotifiViewFactory.shared())')
  updated.gsub!(/(?<!\*\))\bJobsViewPushConfiguration\.defaultConfiguration\s*\(\s*\)/, '((JobsViewPushConfiguration *)JobsViewPushConfiguration.defaultConfiguration())')
  updated.gsub!(/(?<!\*\))\bJobsUserModel\.sharedManager\s*\(\s*\)/, '((JobsUserModel *)JobsUserModel.sharedManager())')
  updated.gsub!(/\bWHToast\s*\.\s*hide\s*\(\s*\)/, "WHToast.hide")
  updated.gsub!(/\b(_?authCodeBtn)\.stop\s*\(\s*\)/, '\1.stop')
  updated.gsub!(/\.resignFirstResponder\s*\(\s*\)/, ".resignFirstResponder")
  updated.gsub!(/\.prepare\s*\(\s*\)/, ".prepare")
  updated.gsub!(/\.reloadData\s*\(\s*\)/, ".reloadData")
  updated.gsub!(/\.realTextField\s*\(\s*\)/, ".realTextField")
  updated.gsub!(/\bself\.config\s*\(\s*\)/, 'self.config')
  updated.gsub!(/\bself\.bundle\s*\(\s*\)/, 'self.bundle')
  updated.gsub!(/\bself\.configuration\.bundle\s*\(\s*\)/, 'self.configuration.bundle')
  if path.include?("JobsVerticalMenuVC@2") || path.include?("FMHomeMainBizSubView")
    updated.gsub!(/\bself\.cellTitleMutArr\s*\(\s*\)/, 'self.cellTitleMutArr')
  end
  updated.gsub!(/\bslot\.component\.config\s*\(\s*\)/, 'slot.component.config')
  updated.gsub!(/\b((?:self\.)?(?:[A-Za-z_]\w*(?:Array|Arr)|history|viewStack|sums))\.removeLastObject\s*\(\s*\)/, '\\1.removeLastObject')
  updated.gsub!(/\bchainReq\.start\s*\(\s*\)/, 'chainReq.start')
  updated.gsub!(/\btask\.resume\s*\(\s*\)/, 'task.resume')
  updated.gsub!(/\bself\.session\.(startRunning|stopRunning)\s*\(\s*\)/, 'self.session.\1')
  updated.gsub!(/\.requestHeaderFieldValueDictionary\s*\(\s*\)/, '.requestHeaderFieldValueDictionary')
  updated.gsub!(/\bsuper\.(initializeData|initializeViews|refreshDataSource)\s*\(\s*\)/, '[super \1]')
  updated.gsub!(/\.currentPlayerManager\.(pause|stop)\s*\(\s*\)/, '.currentPlayerManager.\\1')
  updated.gsub!(/\b((?:self\.)?(?:avPlayerManager|ijkPlayerManager))\.(pause|stop)\s*\(\s*\)/, '\\1.\\2')
  updated.gsub!(/\b(currentPlayerManager)\.(pause|stop)\s*\(\s*\)/, '\\1.\\2')
  updated.gsub!(/\b((?:self\.)?(?:player|observer))\.isFullScreen\s*\(\s*\)/, '\\1.isFullScreen')
  updated.gsub!(/\b((?:self\.)?[A-Za-z_]\w*ottieView)\.(pause|stop)\s*\(\s*\)/, '\\1.\\2')
  updated.gsub!(/\bself\.start\s*\(\s*\)/, 'self.start') if path.include?("YTKChainRequest+Extra")
  updated.gsub!(/\bself\.(pause|stop)\s*\(\s*\)/, 'self.\\1') if path.include?("ZFPlayerExtra@Pods")
  updated.gsub!(/\.value\s*\(\s*\)/, ".value")
  updated.gsub!(/\.(xzm_(?:gif)?(?:[Hh]eader|[Ff]ooter)|mj_(?:header|footer|trailer))\.beginRefreshing\s*\(\s*\)/, '.\\1.beginRefreshing')
  updated.gsub!(/\.(xzm_(?:gif)?(?:[Hh]eader|[Ff]ooter)|mj_(?:header|footer|trailer))\.endRefreshing\s*\(\s*\)/, '.\\1.endRefreshing')
  updated.gsub!(/jobsCurrentDevice\s*\(\s*\)\.orientation\s*\(\s*\)/, "jobsCurrentDevice().orientation")
  updated.gsub!(/\b(data|config)\.range\s*\(\s*\)/, '\\1.range')
  updated.gsub!(/\b((?:self\.)?(?:(?:[A-Za-z_]\w*)?(?:Timer|timer)\w*|t|toStop))\.stop\s*\(\s*\)/, '\\1.jobsStop()')
  updated.gsub!(/\((self->)?(_?[A-Za-z_]\w*(?:Timer|timer)\w*)\)\.stop\s*\(\s*\)/, '(\1\2).jobsStop()')
  updated.gsub!(/\(([^()\n]*\.timer)\)\.stop\s*\(\s*\)/, '(\1).jobsStop()')
  updated.gsub!(/\(([^()\n]+\.getCountDownBtn\(\)\.timer)\)\.stop\s*\(\s*\)/, '(\1).jobsStop()')
  updated.gsub!(/\b((?:self\.)?(?:stateLock|normalLock|recursiveLockInternal|fontLock)|state\.condition)\.unlock\s*\(\s*\)/, '\\1.unlock')
  updated.gsub!(/\b((?:self\.)?(?:[A-Za-z_]\w*(?:Timer|DisplayLink)|timer|displayLink|playLink|inertia)|dl)\.invalidate\s*\(\s*\)/, '\\1.invalidate')
  updated.gsub!(/\bself\s*\.\s*currentDevice\s*\(\s*\)/, "self.jobsCurrentDevice()")
  updated.gsub!(/\bself\s*\.\s*mainBundle\s*\(\s*\)/, "self.jobsMainBundle()")
  updated.gsub!(/\bNSObject\s*\.\s*currentLocale\s*\(\s*\)/, "NSObject.jobsCurrentLocale()")
  updated.gsub!(/\bself\s*\.\s*isSimulator\s*\(\s*\)/, "self.jobsIsSimulator()")
  updated.gsub!(/\.size\.(width|height)\s*\(\s*\)/, '.size.\\1')
  updated.gsub!(/\.(width|height)\s*\(\s*\)/, '.\\1')
  updated.gsub!(/\b((?:JobsMainScreen\(\)|[A-Za-z_]\w*Size|size))\.(width|height)\s*\(\s*\)/, '\\1.\\2')
  updated.gsub!(/\bmake\.(width|height)\s*\(\s*\)/, 'make.\\1')
  updated.gsub!(/([\)\]])\.(width|height)\s*\(\s*\)/, '\\1.\\2')
  loop do
    before_masonry = updated.dup
    updated.gsub!(/\b(make(?:\.[A-Za-z_]\w*)*)\.(width|height)\s*\(\s*\)/, '\\1.\\2')
    break if updated == before_masonry
  end
  if File.basename(path) == "NSArray+Extra.m"
    updated.gsub!(/\bdata\.(width|height)\s*\(\s*\)/, 'data.\\1')
  end
  updated.gsub!(/\bstore\.start\s*\(\s*\)/, "store.start") if File.basename(path) == "UILabel+DSL.m"
  updated.gsub!(/\.machineModel\s*\(\s*\)/, ".machineModel")
  updated.gsub!(/(UIDevice\.currentDevice)\.orientation\s*\(\s*\)/, '\\1.orientation')
  updated.gsub!(/\bself\.resourceBundle\s*\(\s*\)/, "self.resourceBundle") if File.basename(path) == "JobsTheme.m"
  updated.gsub!(/\^(\s*)instancetype\b/, '^\\1id')
  next if updated == source

  File.binwrite(path, updated) if options[:apply]
  changed += 1
  puts [options[:apply] ? "updated" : "would-update", path].join("\t")
end

warn "files=#{changed} mode=#{options[:apply] ? 'apply' : 'dry-run'}"
