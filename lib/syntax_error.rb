module Grammy

	class SyntaxError
		attr_reader :source, :line, :line_number, :column, :sequence, :failed_rule
		# TODO: ast_node
		
		def initialize(*args)
			if args.one?
				raise("expected hash") unless args.first.is_a? Hash
				@source, @line, @line_number, 
				@column, @sequence, @failed_rule = args.first.values_at(
					:source,:line,:line_number,
					:column,:sequence,:failed_rule
				)
			else
				@source, @line, @line_number, @column, @sequence, @failed_rule = *args
			end
		end
		
		def got
			line[column-1]
		end

		def message
			<<-EOERR.gsub(/^\s+/,'')
			SyntaxError
			| in source '#{source}'
			| in line #{line_number} at column #{column}
			| #{line.inspect}
			| #{'-'*column + '^'}
			| Expected: #{failed_rule.to_bnf}
			| In Rule: #{sequence.name} -> #{sequence.to_bnf}
			EOERR
		end

		def to_s
			message
		end
		
		def ==(other)
			if other.is_a? SyntaxError
				@source == other.source &&
				@line == other.line &&
				@line_number == other.line_number &&
				@column == other.column &&
				@sequence == other.sequence &&
				@failed_rule == other.failed_rule
			else
				false
			end
		end
		
		#def ==(other)
		#	case other
		#		when SyntaxError:
		#			@source == other.source &&
		#			@line == other.line &&
		#			@line_number == other.line_number &&
		#			@column == other.column &&
		#			@sequence == other.sequence &&
		#			@failed_rule == other.failed_rule
		#		else
		#			false
		#	end
		#end
	end

end
