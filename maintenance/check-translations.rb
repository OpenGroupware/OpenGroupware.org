#!/usr/bin/ruby
#
# check-translations.pl <path> <reference>
# Checks for missing translations
# <path>      - The path to a directory where trnaslations live, typically
#               /usr/share/opengroupware-XY/translations
# <reference> - A reference translation which is "complete". Might be the German
#             - one for OGo
# Example: check-translations.pl /usr/share/opengroupware.org-1.0a/translations German.lproj
#
# Outputs: LANGUAGE.lproj files with missing translations for each language in <path>
#
# Copyright: 2004, Sebastian Ley <ley@debian.org>
# This is free software, use it for whatever you want.

class Ogo_i18n
  def initialize(path, reference_dir)
    @path = path
    @reference_dir = @path+"/"+reference_dir
    @reference_files = Dir[@reference_dir+"/*.strings"].collect!{|x| x.split('/')[-1] }
    @check_dirs = Dir[@path+"/*.lproj"].delete_if{|x| /.*#{@reference_dir}.*/ =~ x }
  end
  
  def reference_file(file)
    filename = File.split(file)[1]
    return @reference_dir+"/"+filename
  end
  
  def missing_translations_in_dir(language_dir)
    puts "Now checking #{language_dir}"
    f = File.new(language_dir.split('/')[-1], "w")
    result = @reference_files - Dir.entries(language_dir)
    if not result.empty?
      f.puts "Missing files:"
      f.puts "--------------"
      f.puts result
      f.puts ""
    end
    Dir.foreach(language_dir) do |file|
      if /.*\.strings$/ =~ file
        f.puts "Missing translations in #{file}:"
        missing_translations_in_file(language_dir+"/"+file, f)
        f.puts ""
      end
    end
    f.close
  end

  def missing_translations_in_file(file, output)
    reference = reference_file(file)
    return if not File.exist?(reference)
    reference_keys = IO.readlines(reference).delete_if{ |x| not /.*=.*/ =~ x }
    reference_keys.collect!{ |x| x.split('=')[0].strip }

    check_keys = IO.readlines(file).delete_if{ |x| not /.*=.*/ =~ x }
    check_keys.collect!{ |x| x.split('=')[0].strip }

    result = reference_keys - check_keys
    if result.empty?
      output.puts "none"
    else
      output.puts result
    end
  end

  def missing_translations()
    @check_dirs.each{ |dir| missing_translations_in_dir(dir)}
  end

end

o = Ogo_i18n.new(ARGV[0], ARGV[1])
o.missing_translations
