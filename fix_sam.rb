#####
#
# Expects sam sorted by read name!
# out: Fixed sam that is valid for compare2truth.pl
# 1) Readnames end in a for fwd and b for rev
# 2) Fwd read comes before rev
# 3) Add missing reads (?)
# 4) NH and IH tag signalising multi-mappers
#
####

def fix_ab(fields,current_name)
  #STDERR.puts fields
  #STDERR.puts (fields[1].to_i & 2**7).to_s(2)
  if (fields[1].to_i & 2**7).to_s(2)[-8] == "1"
    fields[0] = "#{current_name}b"
  else
    fields[0] = "#{current_name}a"
  end
  fields
end

def check_hi_tag(fields)
  ih = 0
  fields[11..-1].each do |tag|
    if tag =~ /^HI:/
      tag =~ /(\d+)/
      ih = $1.to_i
    end
  end
  fields << ih
end

def fix_lines(lines,current_name)
  #number_of_hits = lines.length/2+1
  #STDERR.puts number_of_hits
  i = 0
  # e[-1] information from IH tag if it exists
  #STDERR.puts lines.join(":")
  lines.sort_by! {|e| [e[-1], e[2], e[3].to_i]}
  #STDERR.puts lines.join(":")
  fwd_reads = []
  rev_reads = []
  lines.each do |line|
    l = fix_ab(line,current_name)
    #second = fix_ab(lines[i*2+1],current_name)
    if l[0] =~ /a$/
      fwd_reads << l
    else
      rev_reads << l
    end
    i = i+1
  end
  if rev_reads.length != fwd_reads.length
    STDERR.puts rev_reads.join(":")
    STDERR.puts fwd_reads.join(":")
    raise "GSNAP case"
  end
  rev_reads.each_with_index do |rev, i|
    fwd = fwd_reads[i]
    puts fwd[0...-1].join("\t")
    puts rev[0...-1].join("\t")
  end

end

sam_file = File.open(ARGV[0])
current_name = ""
lines = []
while !sam_file.eof?
  line = sam_file.readline()
  if line =~ /^@/
    puts line
    next
  end
  line.chomp!
  fields = line.split("\t")
  fields = check_hi_tag(fields)
  if current_name == ""
    #line.chomp!
    #fields = line.split("\t")
    current_name = fields[0][0...-1] if current_name == ""
    lines = [fields]
  else
    lines << fields
  end
  old_name = current_name
  while old_name == current_name && !sam_file.eof?
    line = sam_file.readline()
    line.chomp!
    fields = line.split("\t")
    fields = check_hi_tag(fields)
    lines << fields
    current_name = fields[0][0...-1]
  end

  STDERR.puts current_name
  STDERR.puts old_name
  lines = lines[0...-1] if !sam_file.eof?
  fix_lines(lines,old_name)
  #current_name = fields[0]
  #puts current_name
  #puts lines[-1]
  lines = [fields]
#  exit
end