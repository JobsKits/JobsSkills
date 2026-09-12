#!/usr/bin/env ruby
# frozen_string_literal: true

module JobsSwiftOwnership
  HEADER_LINE_LIMIT = 100

  module_function

  def jobs_owned_source?(source)
    header = source.lines.first(HEADER_LINE_LIMIT)
    return false unless header.any? { |line| line.include?("Created by Jobs") }
    return false if header.any? { |line| line.include?("Created by") && !line.include?("Created by Jobs") }
    return false if header.any? { |line| line.match?(/Copyright/i) && !line.match?(/Jobs/i) }

    true
  end

  def jobs_owned_file?(path, source = nil)
    source ||= File.binread(path)
    utf8_source = source.dup.force_encoding(Encoding::UTF_8)
    utf8_source.valid_encoding? && jobs_owned_source?(utf8_source)
  end
end
