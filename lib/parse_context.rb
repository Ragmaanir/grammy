
require 'syntax_error'

module Grammy

	class ParseContext
		attr_reader :grammar
		attr_reader :stream, :errors, :source, :backtrack_border
		attr_accessor :line_number, :position, :line_start

		def initialize(grammar,source,stream)
			@grammar, @stream, @errors = grammar, stream, []
			@source = source || :unknown
			@position = @line_start = @backtrack_border = 0
			@line_number = 1
		end

		def position=(new_pos)
			raise "new position must be > 0" if new_pos < 0
			raise "cant backtrack behind backtrack border" if new_pos < @backtrack_border

			length = new_pos - @position

			if length < 0 # moving backwards
				part = @stream[new_pos,length.abs]
				newlines = part.count("\n")
				@line_number -= newlines
				@line_start = @stream[0..new_pos].rindex("\n") || 0
			elsif length > 0 # moving forward
				part = @stream[@position,length]
				newlines = part.count("\n")
				@line_number += newlines
				@line_start = part.rindex("\n") + @position + 1 if newlines > 0
			end

			@position = new_pos
		end

		def line
			rest = @stream[@line_start..-1]
			rest[/([^\n]*)\n?/,1] # all characters to next newline or eos
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
	end

end