#!/usr/bin/env ruby
# frozen_string_literal: true

module JobsOCOwnership
  HEADER_LINE_LIMIT = 100
  IMPLEMENTATION_EXTENSIONS = %w[.m .mm].freeze
  EXCLUDED_PATH_MARKERS = [
    "/Pods/",
    "/ManualByOCPods@Pods/",
    "/PodsManual/",
    "/Manual_Add_ThirdParty",
    "/🔨Manual_Add_ThirdParty",
    "/JobsOCTools@Pods/Core/GXCardView（需要重构成单独的Pod）/",
    "/JobsOCTools@Pods/Core/XLChannelControls/",
    "/JobsOCTools@Pods/Core/水平进度条/",
    "/JobsCryptography@Pods/Core/加密（编码）算法/Base编码系列/Base64/GTMBase64（第三方）/",
    "/App工具类/3rd/",
    "/Demo@Excel/Excel-SpreadsheetView/",
    "/Demo@CoreTextLearning/"
  ].freeze

  module_function

  def jobs_owned_source?(source)
    header = source.lines.first(HEADER_LINE_LIMIT)
    return false unless header.any? { |line| line.include?("Created by Jobs") }
    return false if header.any? { |line| line.include?("Created by") && !line.include?("Created by Jobs") }
    return false if header.any? { |line| line.match?(/Copyright/i) && !line.match?(/Jobs/i) }

    true
  end

  def jobs_owned_file?(path, source = nil)
    normalized_path = File.expand_path(path).tr("\\", "/")
    return false if EXCLUDED_PATH_MARKERS.any? { |marker| normalized_path.include?(marker) }

    source ||= File.binread(path)
    return false unless jobs_owned_source?(source)

    extension = File.extname(path)
    return true unless IMPLEMENTATION_EXTENSIONS.include?(extension)

    header_path = path.sub(/\.(?:m|mm)\z/, ".h")
    return true unless File.file?(header_path)

    header_source = File.binread(header_path)
    header_source.dup.force_encoding(Encoding::UTF_8).valid_encoding? && jobs_owned_source?(header_source)
  end
end
