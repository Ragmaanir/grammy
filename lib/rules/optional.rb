require 'rules/rule'

module Grammy
	module Rules
	
		class OptionalRule < Rule
			attr_reader :rule
			
			def initialize(name,child,options={})
				raise("OptionalRule: expected rule but got: #{child}") unless child.is_a? Rule
				@rule = child
				super(name,options)
			end
			
			def children
				[@rule]
			end
			
			def match(context)
				debug_start(context) if rule.debugging?

				match = rule.match(context)
				
				if generating_ast? and match.success? # dont generate node if nothing matched
					children = match.ast_node ? [match.ast_node] : []
					node = create_ast_node(context,[match.start_pos, match.end_pos], children)
				else
					node = nil
				end
				
				result = MatchResult.new(self, true, node, match.start_pos, match.end_pos)

				debug_end(context,result) if rule.debugging?
				result
			end
			
			def first_set
				rule.first_set + [nil]
			end
			
			def to_bnf
				if rule.is_a? RuleReference
					"#{rule.to_bnf}?"
				else
					"[#{rule.to_bnf}]"
				end
			end
			
			def to_s
				to_bnf
			end
		end
	
	end	
end
