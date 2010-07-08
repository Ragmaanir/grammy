
require 'syntax_error'

module Grammy

	class ParseContext
		attr_reader :grammar, :ast_module
		attr_reader :stream, :errors, :source, :backtrack_border
		attr_accessor :line_number, :position, :line_start

		def initialize(grammar,source,stream, options={})
			@grammar, @stream, @errors = grammar, stream, []
			@source = source || :unknown
			@position = @line_start = @backtrack_border = 0
			@line_number = 1
			@ast_module = options[:ast_module]
			
			if @ast_module
				tmp_module = @ast_module
				
				@ast_node_class = Class.new(AST::Node) do
					include tmp_module
				end
			else
				@ast_node_class = AST::Node
			end
		end

		def position=(new_pos)
			raise "new position must be >= 0" if new_pos < 0
			#raise "cant backtrack behind backtrack border" if new_pos < @backtrack_border
			if new_pos < @backtrack_border
				#raise "cant backtrack to '#{new_pos}' because border is at: #{line_number}:#{column} '#{line}'"
				@backtrack_border = new_pos
			end

			#length = new_pos - @position

#			if length < 0 # moving backwards
#				part = @stream[new_pos,length.abs]
#				newlines = part.count("\n")
#				@line_number -= newlines
#				@line_start = @stream[0..new_pos].rindex("\n") || 0
#			elsif length > 0 # moving forward
#				part = @stream[@position,length]
#				newlines = part.count("\n")
#				@line_number += newlines
#				@line_start = part.rindex("\n") + @position + 1 if newlines > 0
#			end

			@line_number = @stream[0,new_pos].count("\n") + 1
			@line_start = @stream[0,new_pos].rindex("\n") || 0
			@line_start += 1 if @line_number > 1

			@position = new_pos
		end

		def line
			rest = @stream[@line_start..-1]
			#rest[/([^\n]*)\n?/,1] # all characters to next newline or eos
			rest[/[^\n]*/]
		end

		def column
			@position - @line_start
		end

		def set_backtrack_border!
			raise if @backtrack_border > @position
			@backtrack_border = @position
		end

		def add_error(sequence,failed_rule)
			@errors << SyntaxError.new(source,line,line_number,column+1,sequence,failed_rule)
			#@errors << SyntaxError.new(source,line,line_number,failure_pos - @line_start,sequence,failed_rule)
		end
		
		def create_ast_node(*args)
			@ast_node_class.new(*args)
		end
	end

end
