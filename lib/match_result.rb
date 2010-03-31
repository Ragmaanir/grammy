module Grammy

	class MatchResult
		attr_reader :rule, :result, :ast_node#, :match_range
		attr_accessor :start_pos, :end_pos

		def initialize(rule,result,ast_node,start_pos,end_pos)
			raise("") unless rule.is_a? Grammy::Rules::Rule
			raise unless [true,false].member? result
			#raise unless range.is_a? Range
			raise if ast_node and not ast_node.is_a? AST::Node
			@rule = rule
			@result = result
			@ast_node = ast_node
			#@match_range = range
			@start_pos = start_pos
			@end_pos = end_pos
		end

		def length
			end_pos - start_pos
		end

		def success?
			@result
		end

		def fail?
			not success?
		end

		def to_s
			res_str = @result ? 'success' : 'fail'
			"#{@rule.rule_type}.match: #{res_str}"
		end
		
	end

end