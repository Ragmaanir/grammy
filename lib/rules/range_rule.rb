require 'rules/rule'

module Grammy
	module Rules
		#
		# RangeRule
		#
		class RangeRule < LeafRule
			attr_reader :range

			def initialize(name,range,options={})
				super(name,options)
				raise "range must be range but was: '#{range}'" unless range.is_a? Range
				@range = range
			end

			def match(context)
				debug_start(context)
				success = false
				skip(context) if skipping?

				end_pos = start_pos = context.position

				matched_element = @range.find { |elem|
					if elem == context.stream[start_pos,elem.length]
						context.position += elem.length
						success = true
					end
				}

				end_pos = context.position

				node = create_ast_node(context,[start_pos,end_pos]) if success and not ignored?
				match = MatchResult.new(self,success,node,start_pos,end_pos)
				debug_end(match)
				match
			end

			def to_s
				"(#{@range.min}..#{@range.max})"
			end

			def to_bnf
				to_s
			end
		end # RangeRule

	end # Rules
end # Grammy