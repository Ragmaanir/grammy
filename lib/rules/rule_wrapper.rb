require 'rules/rule'

module Grammy
	module Rules
		#
		# RULE WRAPPER rule
		# Wraps a symbol which represents another rule which may be not defined yet.
		# When the symbol ends with '?', then the rule is optional
		class RuleWrapper < Rule
			def initialize(sym,options={})
				raise("sym has to be a symbol but was: '#{sym}'") unless sym.is_a? Symbol
				@optional = options[:optional] || false
				if sym[-1]=='?'
					@optional = true
					sym = sym[0..-2].to_sym
				end
				@symbol = sym
				super(@symbol,options)
			end

			def optional?
				@optional
			end

			def grammar=(gr)
				# dont set grammar for children because the wrapped rule might not be defined yet
				# also the wrapped rule has a name (defined via rule-method), so it will get assigned a grammar anyway
				@grammar = gr
			end

			def children
				rule.children
			end

			def rule
				grammar.rules[@symbol] || raise("RuleWrapper: rule not found '#{@symbol}'")
			end

			def match(context)
				debug_start(context)

				match = rule.match(context)

				success = match.success? || optional?

				result = MatchResult.new(self, success, match.ast_node, match.start_pos, match.end_pos)

				debug_end(result)
				result
			end

			def to_s
				":#{name}#{optional? ? '?' : ''}"
			end

			def to_bnf
				"#{name}#{optional? ? '?' : ''}"
			end
		end # Wrapper

	end # Rules
end # Grammy