#!/usr/bin/env ruby
require 'optparse'
require 'csv'
require 'bio'
require 'bio-faidx'


$: << File.expand_path(File.dirname(__FILE__) + '/../lib')
$: << File.expand_path('.')
path= File.expand_path(File.dirname(__FILE__) + '/../lib/bio-agp-tools.rb')
require path

options = {}


OptionParser.new do |opts|
  
  opts.banner = "Usage: agp_add_local_order.rb [options]. The transformations only occur on blocks"

  opts.on("-o", "--order FILE", "File with the initial order. ") do |o|
    options[:order_file] = o
  end

  opts.on("-i", "--agp_input FILE", "File with the input AGP file to be transformed") do |o|
  	options[:list_of_fasta_files] = o
  end

  opts.on("-a", "--agp_output FILE", "File to write the AGP output") do |o|
  	options[:agp_output] = o
  end
  
end.parse!