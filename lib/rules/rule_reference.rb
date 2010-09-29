require 'rules/rule'

module Grammy
	module Rules

	#
	# RULE REFERENCE rule
	# Wraps a symbol which represents another rule which may be not defined yet.
	# When the symbol ends with '?', then the rule is optional
	class RuleReference < Rule
		def initialize(sym,options={})
			raise("sym has to be a symbol but was: '#{sym}'") unless sym.is_a? Symbol
			raise("invalid rule name: #{sym}") if /[?!=]/ === sym.to_s
			
			@referenced_rule_name = sym
			super(@referenced_rule_name,options)
		end

		def grammar=(gr)
			# dont set grammar for children because the referenced rule might not be defined yet
			# also the referenced rule has a name (defined via rule-method), so it will get assigned a grammar anyway
			@grammar = gr
		end

		def children
			rule.children
		end

		def referenced_rule
			grammar.rules[@referenced_rule_name] || raise("RuleReference: rule not found '#{@referenced_rule_name}'")
		end

		def match(context)
			debug_start(context)# if rule.debugging?

			match = referenced_rule.match(context)
			
			if generating_ast? and match.success? # dont generate node if nothing matched
				children = match.ast_node ? [match.ast_node] : []
				node = create_ast_node(context,[match.start_pos, match.end_pos], children)
			else
				node = nil
			end
			
			result = MatchResult.new(self, match.success?, node, match.start_pos, match.end_pos)

			debug_end(context,result)# if rule.debugging?
			result
		end
		
		def first_set
			referenced_rule.first_set
		end

		def to_s
			to_bnf
		end

		def to_bnf
			name
		end
	end # RuleReference

	end # Rules
end # Grammy
