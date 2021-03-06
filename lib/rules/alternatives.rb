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

				skip(context) if using_skipper?
				start_pos = context.position

				success = @children.find { |e|
					context.position = start_pos
					match = e.match(context)
					match.success? or not match.backtracking? # dont try other alternatives when a subrule disabled backtracking
				}

				if generating_ast?
					children = []
					children << match.ast_node if match.ast_node
					node = create_ast_node(context,[start_pos,match.end_pos],children)
				end

				result = MatchResult.new(self,!!success,node,start_pos,match.end_pos)
				debug_end(context,result)
				result
			end
			
			def first_set
				@children.map(&:first_set).to_set.flatten
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
