module Grammy

	class SyntaxError
		attr_reader :source, :line, :line_number, :column, :sequence, :failed_rule

		def initialize(*args)
			@source, @line, @line_number, @column, @sequence, @failed_rule = *args
		end

		def message
			<<-EOERR.gsub(/^\s+/,'')
			Syntax error
			| in source '#{source}'
			| in line #{line_number} at column #{column}
			| #{line.inspect}
			| Expected: #{failed_rule.to_bnf}
			| In Rule: #{sequence.name} -> #{sequence.to_bnf}
			EOERR
		end

		def to_s
			message
		end
	end

end