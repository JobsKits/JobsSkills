#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "jobs_oc_ownership"

APPLY_FLAG = "--apply"
QUOTED_IMPORT_LINE = /^\s*#\s*import\s+"[^"\r\n]+\.h"\s*(?:\r?\n|\z)/
ACTIVE_QUOTED_IMPORT = /^\s*#\s*import\s+"/
EXCLUDED_COMPONENTS = %w[.git Pods node_modules .dart_tool build DerivedData].freeze

apply = ARGV.delete(APPLY_FLAG)
roots = ARGV.empty? ? [Dir.pwd] : ARGV
files = roots.flat_map do |root|
  path = File.expand_path(root)
  File.file?(path) ? [path] : Dir.glob(File.join(path, "**", "*.m"))
end.select { |path| File.file?(path) && File.extname(path) == ".m" }
  .reject do |path|
    path.split(File::SEPARATOR).any? { |component| EXCLUDED_COMPONENTS.include?(component) }
  end
  .uniq
  .sort

owned_files = 0
changed_files = 0
removed_blank_lines = 0
invalid_lines = []
blank_gaps = []

files.each do |path|
  source = File.binread(path)
  source = source.dup.force_encoding(Encoding::UTF_8)
  next unless source.valid_encoding?
  next unless JobsOCOwnership.jobs_owned_file?(path, source)

  owned_files += 1
  lines = source.lines
  lines.each_with_index do |line, index|
    next unless line.match?(ACTIVE_QUOTED_IMPORT)
    next if line.match?(QUOTED_IMPORT_LINE)

    invalid_lines << [path, index + 1, line.chomp]
  end

  index = 0
  file_blank_gaps = 0
  while index < lines.length
    unless lines[index].match?(QUOTED_IMPORT_LINE)
      index += 1
      next
    end

    following = index + 1
    following += 1 while following < lines.length && lines[following].match?(/^\s*(?:\r?\n|\z)/)
    if following > index + 1 && following < lines.length && lines[following].match?(QUOTED_IMPORT_LINE)
      gap_size = following - index - 1
      blank_gaps << [path, index + 1, following + 1, gap_size]
      file_blank_gaps += gap_size
      lines.slice!(index + 1, gap_size) if apply
    end
    index += 1
  end

  next if file_blank_gaps.zero?

  changed_files += 1
  removed_blank_lines += file_blank_gaps
  next unless apply

  File.binwrite(path, lines.join)
end

display_roots = roots.map { |root| File.expand_path(root) }
relative_path = lambda do |path|
  root = display_roots.select { |candidate| path == candidate || path.start_with?("#{candidate}/") }
                      .max_by(&:length)
  root ? path.delete_prefix("#{root}/") : path
end

invalid_lines.each do |path, line_number, line|
  puts "manual-review\t#{relative_path.call(path)}\t#{line_number}\t#{line}"
end
blank_gaps.each do |path, first_line, second_line, count|
  action = apply ? "fixed" : "would-fix"
  puts "#{action}\t#{relative_path.call(path)}\t#{first_line}\t#{second_line}\tblank_lines=#{count}"
end
puts [
  "mode=#{apply ? "apply" : "dry-run"}",
  "owned_m_files=#{owned_files}",
  "changed_files=#{changed_files}",
  "removed_blank_lines=#{removed_blank_lines}",
  "invalid_lines=#{invalid_lines.length}",
  "blank_gaps=#{blank_gaps.length}"
].join(" ")
