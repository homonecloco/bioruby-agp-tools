
module Bio
	class Assembly
		class Scaffold
      # An Array of ScaffoldedComponent objects
      attr_accessor :scaffolded_components
      
      def initialize
      	@scaffolded_components = []
      end
      
      class ScaffoldedComponent
      	attr_accessor :object_id, :object_beg, :object_end, :part_number, :component_type
      end
      
      # non- 'N' or 'U' type components
      class ScaffoldedObject < ScaffoldedComponent
      	attr_accessor :component_type, :component_id, :component_begin, :component_end, :orientation
      	def length
      		@component_end - @component_begin
      	end

      	def to_s
      		"#{object_id}\t#{object_beg}\t#{object_end}\t#{part_number}\t#{component_type}\t#{component_id}\t#{component_begin}\t#{component_end}\t#{orientation}"
      	end

      	def self.parse_row(row)
      		component = Bio::Assembly::Scaffold::ScaffoldedObject.new

      		[:object_id, :object_beg, :object_end, :part_number, :component_type, 
      			:component_id, :component_begin, :component_end, :orientation].each_with_index do |sym, i|
      				answer = row[i]
      				answer = answer.to_i if [:object_beg, :object_end, :component_begin, :component_end].include?(sym)
      				component.send("#{sym}=".to_sym, answer)
      			end
      		end
      	end



      # 'N' or 'U' type components
      class ScaffoldedGap < ScaffoldedComponent
      	attr_accessor :gap_length, :gap_type, :linkage, :linkage_evidence
      	def to_s
			"#{object_id}\t#{object_beg}\t#{object_end}\t#{part_number}\t#{component_type}\t#{gap_length}\t#{gap_type}\t#{linkage}\t#{linkage_evidence}"
      	end

      	def self.parse_row(row)
      		component = Bio::Assembly::Scaffold::ScaffoldedGap.new

      		[:object_id, :object_beg, :object_end, :part_number, :component_type, 
      			:gap_length, :gap_type, :linkage, :linkage_evidence].each_with_index do |sym, i|
      				if row[i]
      					answer = row[i] 
      					answer = answer.to_i if [:object_beg, :object_end, :gap_length].include?(sym)
      					component.send("#{sym}=".to_sym, answer)
      				end
      			end
      			component
      		end
      	end
      end
      
      class AGP
      	include Enumerable
      	attr_accessor :cache
      	attr_reader :scaffolds
      	def initialize(opts)
      		@cache = opts[:cache] if opts[:cache]
      		@filename = opts[:filename]
      		@scaffolds_fasta_list = opts[:scaffolds_fasta_list]
      		load_scaffold_fais if @scaffolds_fasta_list
      	end

      	def each
      		@scaffolds.each do |scaff|
      			yield scaff
      		end 
      	end

      	def << (component)
      		@scaffolds = Array.new unless @scaffolds
      		throw Exception "Adding something that is not a component" unless component.is_a? Bio::Assembly::Scaffold::ScaffoldedComponent
      		#puts "Adding: #{component.to_s}"
      		@scaffolds.push( component)
      	end

      	def load_scaffold_fais
      		@fais = Hash.new

      		CSV.foreach(@scaffolds_fasta_list, :col_sep => "\t") do |row|
      			@fais[row[0]] = Bio::DB::Faidx.new({:cache=>true, :filename=>row[1] + ".fai"})
      		end
      	end

      	def load_scaffolds_with_full_length!
      		each do |scaff|
      			#puts scaff.component_id
      			next unless scaff.respond_to?(:component_id)
      			fai = @fais[scaff.object_id]
      			entry = fai[scaff.component_id]
      			scaff.component_begin = 1
      			scaff.component_end = entry.length
      		end
      	end

      	def calculate_agp_positions!
      		start_position = 1
      		each do |scaff|
      			start_position = 1 if scaff.part_number == 1
      			length = scaff.component_end - scaff.component_begin if scaff.respond_to?(:component_id)
      			length = scaff.gap_length if scaff.respond_to?(:gap_length)
      			new_end = start_position + length

      			scaff.object_beg = start_position
      			scaff.object_end = new_end 
      			start_position = new_end + 1
      		end
      	end
      	

      # Iterate through scaffolds, yielding a Scaffold object at each point
      def each_scaffold
      	@scaffolds.each_scaffold do |scaff|
      		yield
      	end if @scaffolds
      	return if @scaffolds
      	@scaffolds = Array.new if  @cache
      	scaff = Scaffold.new

      	CSV.foreach(@filename, :col_sep => "\t", :skip_lines=>/^#/, :skip_blanks=>true) do |row|
          #p row
          component = nil
          if %w(N U).include?(row[4])
          	component = Bio::Assembly::Scaffold::ScaffoldedGap.parse_row(row)
          else
          	component = Bio::Assembly::Scaffold::ScaffoldedObject.parse_row(row)
          end
          unless scaff.object_id == component.object_id
          	yield scaff
          	@scaffolds << scaff 
          	scaff = Scaffold.new
          end
          scaff.scaffolded_components.push component
      end
        yield scaff #yield the last scaffold
        @scaffolds << scaff 
    end
end
end
end