require 'rules/rule'

module Grammy
	module Rules
		#
		# StringRule
		#
		class StringRule < LeafRule
			attr_reader :string

			def initialize(string,options={})
				super(nil,options)
				raise unless string.is_a? String
				@string = string
			end

			def match(context)
				debug_start(context)

				node = nil
				end_pos = start_pos = context.position
				success = (@string == context.stream[start_pos,@string.length])

				if success
					end_pos += @string.length
					context.position = end_pos
					node = create_ast_node(context,[start_pos,end_pos]) if generating_ast?
				end

				match = MatchResult.new(self,success,node,start_pos,end_pos)

				debug_end(context,match)
				match
			end

			def to_s
				"'#{@string}'"
			end

			def to_bnf
				to_s
			end
		end # StringRule

	end # Rules
end # Grammy