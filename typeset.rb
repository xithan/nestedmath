# Erstellt fuer jede Definition und jeden Raum eine eigene PDF-Datei

require 'byebug'

# paths for input data
$indir = "tex/"
$bibfile = "example"
$infile = "example"
$bibfile = "example"
$packagedir = "packages/"

$workdir = "tmp/"

# paths for output data
$mainfile = "main"
$outdir = "pdfviewer/web/pdf/"
$bibdir = "pdfviewer/web/pdf/bib/"
$bibstyle = "alpha"


$glos = {}

$no_ref = ARGV.include?("-no-ref")
$no_gls = ARGV.include?("-no-gls")
$no_sec = ARGV.include?("-no-sec")
$no_typeset = ARGV.include?("-no-typeset")
$no_cleanup = ARGV.include?("-no-cleanup")

def readtex(file)
  filestack = [File.new($indir+file+".tex","r")]
  $documentclass =  filestack.last.readline()
  raise TeXError unless /\\documentclass/.match($documentclass)
  document = false
  comment = false
  while not filestack.empty?
    begin
      line = filestack.last.readline()
      if /^\s*\\end\{markas\}/.match(line)
        comment = false
      elsif /^\s*%.*$/.match(line) or comment
        next
      elsif /\\bibliography/.match(line)
        next 
      elsif /^\s*\\begin\{markas\}/.match(line)
        comment = true
      elsif /^\s*\\begin\{document\}/.match(line)
        document = true
        yield(line)
      elsif sub = /\\(?:input|include)\{([^}]+)\}/.match(line) #and document
        filestack.push(File.new($indir+sub[1] + ".tex","r"))
      else
        yield(line)
      end
    rescue EOFError
      filestack.pop.close()
    end
  end
end

def parse_preamble(line)
  $preamble_file.write(line)
end

def parse_room(line)
  $target.write(line)
  if entry = /^\s*\\\w*nodei?[^{\s]*\{([^}]+)\}/.match(line) 
    $glos[entry[1]] = true
  end
end

def parse_emergency(line)
  if entry = /^\s*\\\w*nodei?[^{\s]*\{([^}]+)\}/.match(line) 
    $glos[entry[1]] = true
  end
end

def new_texfile(filename, type)
  file = File.open($workdir+filename+".tex", "w") # Alles weitere in die Hauptdatei
  file.puts($documentclass)
  file.puts('\include{preamble}')
  if type == :mathview
    file.puts('\mathview')
  elsif type == :defview
    file.puts('\defview')
  end
  file.puts("\\bibliographystyle{#{$bibstyle}}")
  file.puts('\begin{document}')
#  file')\\nobibliography{#{$bibfile}}
#file.puts("\\newsavebox\\mytempbib
# => \\savebox\\mytempbib{\\parbox{\\textwidth}{\\bibliography{#{$bibfile}}}}")
  file.puts("\\nobibliography{#{$bibfile}}")
  return file
end


def close_file(file)
  file.puts '\end{document}'
  file.close
end

def cleanup
  puts "clean up"
  FileUtils.rm_rf($workdir)
end

def run_initex filename
  puts "Run initex #{filename}"
  return system( "cd #{$workdir}; pdfetex '-ini' '-interaction=batchmode' '-file-line-error' '&pdflatex' './#{filename}.ini' >/dev/null" )
end

def run_bibtex name, workdir = $workdir
  puts "Run bibtex #{name}"
  return system( "cd #{workdir}; bibtex #{name} >/dev/null" )
end

def run_latex name, format=:latex, workdir = $workdir
  case format
  when :latex
    puts "Run latex #{workdir}#{name}"
    return system("cd #{workdir}; latex './#{name}.tex' >/dev/null")
  when :pdflatex 
    puts "Run pdflatex #{workdir}#{name}"
    return system("cd #{workdir}; pdflatex './#{name}.tex' >/dev/null")
  else
    puts "Run pdfetex #{workdir}#{name}"
    return system("cd #{workdir}; pdfetex -output-format pdf '-interaction=batchmode' -file-line-error -synctex=0 -fmt '#{format}'  './#{name}.tex' >/dev/null")
  end
end

def move_file filename, ending, outdir=$outdir
  puts "moved #{$workdir}#{filename}.#{ending} to #{outdir}#{filename}.#{ending}"
  FileUtils.cp("#{$workdir}#{filename}.#{ending}", "#{outdir}#{filename}.#{ending}")
end

def move_pdf filename, outdir=$outdir
  move_file filename, "pdf", outdir
end

def move_svg filename, outdir=$outdir
  move_file filename, "svg", outdir
end

def run_dvitosvg name, workdir = $workdir
  return system("cd #{workdir}; dvisvgm -n './#{name}'")
end

def typeset(file = $outfile, format = :mathview)
  if (format == :defview and $no_gls) or $no_typeset or (format == :mathview and $no_sec)
    return
  end
  puts "##########################################"
  puts "Process #{file}"
  run_latex  file, format.to_s
  if format == :mathview
    run_bibtex file
    run_latex  file, format.to_s
    run_latex  file, format.to_s
  end
end

def typeset_preamble workdir=$workdir
  puts "##########################################"
  puts "Process preamble"
  File.open(workdir+"defview.ini", "w") { |file|  # Alles weitere in die Hauptdatei
    file.puts($documentclass)
    file.puts('\input{preamble}')
    file.puts('\defview')
    file.puts('\dump')
  }
  
  File.open(workdir+"mathview.ini", "w") { |file| # Alles weitere in die Hauptdatei
    file.puts($documentclass)
    file.puts('\input{preamble}')
    file.puts('\mathview')
    file.puts('\dump')
  }
  
  run_initex "mathview"
  run_initex "defview"
end

def bibitem_template bibitem
  %{\\documentclass[10pt]{article}
\\usepackage{#{$packagedir}screenread}
\\usepackage{hyperref}
\\renewcommand\\refname{\\vspace{-1cm}}
\\begin{document}
  \\nocite{*}
  \\begin{thebibliography}{1}
  #{bibitem}
  \\end{thebibliography}
\\end{document}
  }
end

def typeset_references
  puts "Typeset references"
  run_latex $infile, :latex
  run_bibtex $infile
  bibitems = File.read($workdir+$infile+".bbl").scan /(\\bibitem(?:\[[^\]]+\])?\{([^}]+)\}.+?\n\n)/m
  bibitems.each do |ref|
    File.open($workdir+ref[1]+".tex","w") { |f| f.puts( bibitem_template(ref[0]) )}
    unless $no_typeset
      run_latex ref[1], :latex 
      run_dvitosvg ref[1]
      move_svg ref[1], $bibdir
    end
  end
end

def typeset_mainfile
  main_file = new_texfile($mainfile,:mathview)
  File.read($workdir+$infile+".tex").scan(/\\begin\{document\}(.*)\\end\{document\}/m)
  main_document = $1
  main_document.sub!(/\\bibliography\{[^}]*\}/, '')
  main_document.sub!(/\\bibliographystyle\{[^}]*\}/, '')
  main_file.write(main_document)
  close_file(main_file)
  typeset($mainfile)
  move_pdf($mainfile)
end


FileUtils.copy_entry $indir, $workdir

unless $no_ref
  typeset_references
end

$room_cnt = 0
parse = :parse_preamble
$preamble_file = File.open($workdir+"preamble.tex","w")

readtex($infile) do |line|
  if /\\begin\{document\}/.match(line)
    $preamble_file.close() # Praeamble zuende
    typeset_preamble()
    parse = nil
  elsif /\\end\{document\}/.match(line)
    close_file($target)
    typeset($outfile)
    move_pdf($outfile)
  elsif room = /^\s*(?:\\room|\\setroom|roomprooftree|roomproofonly(?:noqed)?\})\s*\{([^}]+)\}/.match(line) 
    $room_cnt += 1
    if $room_cnt >= 3
      close_file($target)
      typeset($outfile)
      move_pdf($outfile)
    end
    if $room_cnt >= 2
      $outfile = room[1]
      $target = new_texfile($outfile,:mathview)
      $target.write(line)
      parse = :parse_room
    end
  elsif /^\s*\\(?:emergency|roomservice)/.match(line)
    parse = :parse_emergency
  else
    send(parse,line) if parse
  end
end

typeset_mainfile

unless $no_gls
  puts "##########################################"
  puts "Process definitions #{$glos.keys.inspect}"
  $glos.each_key do |key|
    file = new_texfile(key, :defview)
    file.write('\begin{treedef}\rootnode{'+key+'}\end{treedef}\end{document}')
    file.close
    typeset(key, :defview)
    system("cd #{$workdir}; pdfcrop --margins 5 #{key}.pdf #{key}.pdf")
    move_pdf key
  end
end

unless $no_cleanup
  cleanup
end

