require 'rules/rule'

module Grammy
	module Rules
		#
		# EOSRule
		# - matches the end of the stream
		# - when skipping: skips characters until end of stream reached
		class EOSRule < LeafRule
			def initialize(options={})
				super(nil,options)
			end

			def match(context)
				debug_start(context)

				skip(context) if skipping?
				end_pos = start_pos = context.position
				success = context.stream[end_pos] == nil

				context.position = end_pos if success

				match = MatchResult.new(self,success,nil,start_pos,end_pos)

				debug_end(context,match)
				match
			end

			def to_s
				"EOS"
			end

			def to_bnf
				to_s
			end
		end
	end # Rules
end # Grammy