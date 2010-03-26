module Grammy

	class MatchResult
		attr_reader :rule, :result, :ast, :range

		def initialize(rule,result,ast,range)
			raise("") unless rule.is_a? Rule
			raise unless [true,false].member? result
			raise unless range.is_a? Range
			@rule = rule
			@result = result
			@ast = ast
			@range = range
		end

		def success?
			@result
		end

		def fail?
			not success?
		end
		
	end

end