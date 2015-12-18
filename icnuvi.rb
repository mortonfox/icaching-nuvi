require_relative 'generate'
require 'optparse'

outdir = '.'

optp = OptionParser.new

optp.banner = <<-EOM
Usage: #{File.basename $PROGRAM_NAME} [options] folder [folder...]

Generate GPX files from Icaching folders.

EOM

optp.on('-dDIR', '--output-dir=DIR', 'Specify output directory. Default: current directory') { |dir|
  outdir = dir
}

optp.on('-h', '-?', '--help', 'Print this help.') {
  puts optp
  exit
}

optp.parse!

folders = ARGV

if folders.empty?
  warn 'You must specify at least one folder!'
  puts optp
  exit
end

gen = IcachingNuvi::Generate.new

folders.each { |folder|
  gen.process_folder folder, outdir
}

__END__
