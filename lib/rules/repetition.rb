require 'rules/rule'

module Grammy
	module Rules

		#
		# REPETITION
		#
		class Repetition < Rule
			attr_accessor :repetitions
			attr_reader :rule

			def initialize(name,rule,options={})
				rule = Rule.to_rule(rule)
				@rule = rule
				@rule.parent = self
				@repetitions = options[:times] || raise("no repetition supplied")
				super(name,options)
			end

			def children
				[@rule]
			end

			def match(context)
				success = false # set to true when repetition in specified range
				failed = false # used for the loop
				cur_pos = start_pos = context.position

				results = []

				debug_start(context)

				while not failed and results.length < repetitions.max
					skip(context) if using_skipper?
					match = @rule.match(context)

					if match.success?
						results << match
					else
						failed = true
					end
				end

				success = repetitions.include? results.length
				end_pos = success ? context.position : start_pos

				if generating_ast?
					children = results.map{|res| res.ast_node }.compact
					node = create_ast_node(context,[start_pos,end_pos],children)
				end

				result = MatchResult.new(self, !!success, node, start_pos, end_pos)
				debug_end(context,result)
				result
			end
			
			def first_set
				set = rule.first_set
				set << nil if repetitions.include?(0)
				set
			end

			def to_s
				rule_str = @rule.to_s
				rule_str = "(#{rule_str})" if [Sequence,Alternatives,Repetition].include? @rule.class

				if repetitions == (0..MAX_REPETITIONS)
					"~#{rule_str}"
				elsif repetitions == (1..MAX_REPETITIONS)
					"+#{rule_str}"
				elsif repetitions.min == repetitions.max
					"#{rule_str}*#{repetitions.min}"
				else
					"#{rule_str}*#{repetitions}"
				end
			end

			def to_bnf
				rule_str = @rule.to_bnf
				rule_str = "(#{rule_str})" if [Sequence,Alternatives,Repetition].include? @rule.class

				if repetitions == (0..MAX_REPETITIONS)
					"#{rule_str}*"
				elsif repetitions == (1..MAX_REPETITIONS)
					"#{rule_str}+"
				elsif repetitions.min == repetitions.max
					"#{rule_str}[#{repetitions.min}]"
				else
					"#{rule_str}[#{repetitions}]"
				end
			end
		end # Repetition

	end # module Rules
end # module Grammy
