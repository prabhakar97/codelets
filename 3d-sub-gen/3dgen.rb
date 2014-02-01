Dir.entries(".").each do |file|
  if file.include? "3D"
    puts "3D movie found - #{file}. Going ahead to generate .ass subtitle for it"
    Dir.entries(file).each do |file1|
      if file1.include? ".srt"
        puts "Found srt file: #{file1}"
        outfile_name = "#{file1[0,file1.length-3]}ass"
        puts "Out file name : #{outfile_name}"
        `sub3dtool "#{file}/#{file1}" --3dsbs -o "#{file}/#{outfile_name}"`
        puts "Generated successfully"
      end
    end
  end
end
