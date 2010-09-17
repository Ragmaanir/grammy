
require 'extensions/removable_module'

module Grammy
	module Rules

		MAX_REPETITIONS = 5_000

		# Special operators used in the Grammar DSL.
		# The module is designed to be removable so the extra operators
		# wont pollute String, Symbol and Range.
		module Operators
		
			extend ExcludableModule

			def &(right)
				right = Rule.to_rule(right)
				right.backtracking = false
				Sequence.new(nil,[self,right])
			end

			def >>(other)
				Sequence.new(nil,[self,other])
			end

			def |(other)
				Alternatives.new(nil,[self,other])
			end

			def *(times)
				times = times..times if times.is_a? Integer
				raise("times must be a range or int but was: '#{times}'") unless times.is_a? Range

				Repetition.new(nil,Rule.to_rule(self),times: times)
			end

			def +@
				Repetition.new(nil,self,times: 1..MAX_REPETITIONS)
			end

			def ~@
				Repetition.new(nil,self,times: 0..MAX_REPETITIONS)
			end
		end

	end

end
