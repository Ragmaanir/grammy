module Grammy

	class MatchResult
		attr_reader :rule, :result, :ast_node
		attr_accessor :start_pos, :end_pos
		attr_writer :backtracking

		# start_pos is the index of the first matched character
		# end_pos is the index of the character that follows the last matched character
		def initialize(rule,result,ast_node,start_pos,end_pos)
			raise("expected a rule but was: #{rule.inspect}") unless rule.is_a? Grammy::Rules::Rule
			raise unless [true,false].member? result
			raise if ast_node and not ast_node.is_a? AST::Node
			@rule = rule
			@result = result
			@ast_node = ast_node
			@start_pos = start_pos
			@end_pos = end_pos
			@backtracking = true
		end

		def length
			end_pos - start_pos
		end

		# An alternative rule has to check if a subrule disabled backtracking.
		def backtracking?
			@backtracking
		end

		def success?
			@result
		end

		def failure?
			not success?
		end

		def to_s
			res_str = @result ? 'success' : 'fail'
			"#{@rule.rule_type}.match: #{res_str}"
		end
		
	end

end