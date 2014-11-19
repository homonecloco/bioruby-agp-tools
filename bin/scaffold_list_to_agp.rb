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

options[:validate_name] = false



OptionParser.new do |opts|
  
  opts.banner = "Usage: scaffold_list_to_agp.rb [options]"

  opts.on("-o", "--order FILE", "File with the initial order. ") do |o|
    options[:order_file] = o
  end

  opts.on("-f", "--list_of_fasta_files FILE", "File with the list of fasta files containign the components") do |o|
  	options[:list_of_fasta_files] = o
  end

  opts.on("-a", "--agp_output FILE", "File to write the AGP output") do |o|
  	options[:agp_output] = o
  end

  opts.on("-v", "--validate_name", "If set, the object_id must be included in the component_id") do |o|
  	options[:validate_name] = true
  end
  
end.parse!

def new_component(object_id, component_id, part_number)
	component = Bio::Assembly::Scaffold::ScaffoldedObject.new
	
	component.object_id = object_id
	component.object_beg = 0
	component.object_end = 0
	component.part_number = part_number
	component.component_type = "W" 
    component.component_id = component_id
    component.component_begin = 0
    component.component_end = 0
    component.orientation = "?"
	return component
end

def new_gap(objet_id, gap_size, part_number)
	component = Bio::Assembly::Scaffold::ScaffoldedGap.new
	
	component.object_id = objet_id
	component.object_beg = 0
	component.object_end = 0
	component.part_number = part_number
	component.component_type = "U" 
    component.gap_length = gap_size
    component.gap_type = "scaffold"
    component.linkage = "yes"
    component.linkage_evidence = "map"

	return component
end

def component_in_chromosome(component)
	component.component_id.index(component.object_id) != nil
end

agp = Bio::Assembly::AGP.new(:scaffolds_fasta_list=>options[:list_of_fasta_files])
part_number = 0
last_component = false
last_row = false
CSV.foreach(options[:order_file], :col_sep => "\t", :skip_lines=>/^#/, :skip_blanks=>true, :headers=>true) do |row|
	#puts row[0] 
	part_number = 0 if last_component and last_row[1] != row[1]
	part_number += 1
	component = new_component(row[1], row[0] ,part_number)
	gap_size = 100
	gap_size = 500 if last_row and row[2].to_f != last_row[2].to_f
	part_number += 1
	gap = new_gap(row[1], gap_size, part_number)

	add = true
	add = component_in_chromosome(component) if options[:validate_name]

	if add
		agp << component
		agp << gap
    	last_component = component
    	last_row = row
	end
end
puts "Loaded order"


agp.load_scaffolds_with_full_length!
puts "Loaded component_sizes"
agp.calculate_agp_positions!
puts "Postions calculated"

File.open(options[:agp_output], "w") do |file|  
	agp.each do |component |
		file.puts component.to_s
	end
end

puts "done"