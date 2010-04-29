require 'rules/rule'

module Grammy
	module Rules

		#
		# ALTERNATIVE
		#
		class Alternatives < Rule
			attr_reader :children

			def initialize(name,alts,options={})
				@children = []
				alts.each { |alt|
					alt = Rule.to_rule(alt)
					if alt.is_a? Alternatives
						@children.concat(alt.children)
					else
						@children << alt
					end
				}

				@children.each{|c| c.parent = self }
				super(name,options)
			end

			def match(context)
				debug_start(context)
				match = nil

				skip(context) if skipping?
				start_pos = context.position

				success = @children.find { |e|
					context.position = start_pos
					match = e.match(context)
					match.success? or not match.backtracking? # dont try other alternatives when a subrule disabled backtracking
				}

				unless ignored?
					node = create_ast_node(context,[start_pos,match.end_pos])
					node.add_child(match.ast_node) if match.ast_node
				end

				result = MatchResult.new(self,!!success,node,start_pos,match.end_pos)
				debug_end(result)
				result
			end

			def to_s
				"#{@children.join(" | ")}"
			end

			def to_bnf
				"#{@children.map(&:to_bnf).join(" | ")}"
			end
		end # Alternatives

	end # Rules
end # Grammy