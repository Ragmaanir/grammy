require 'rules/rule'

#
# RegexRule
#
class Grammy::Rules::RegexRule < Grammy::Rules::LeafRule
	attr_reader :regex
	
	def initialize(regex,options={})
		raise "regexp expected but got: #{regex.inspect}" unless regex.is_a? Regexp
		
		#@regex = regex
		@regex = /#{regex.source}/u #Regexp.new(regex.source,regex.options)
	end

	def match(context)
		debug_start(context)

		node = nil
		end_pos = start_pos = context.position
		
		regex_match = @regex.match(context.stream[start_pos..-1])
		success = if regex_match && (regex_match.begin(0) == 0) then true else false end

		if success
			end_pos += regex_match[0].length
			context.position = end_pos
			node = create_ast_node(context,[start_pos,end_pos]) if generating_ast?
		end

		match = Grammy::MatchResult.new(self,success,node,start_pos,end_pos)

		debug_end(context,match)
		match
	end

	def to_s
		"/#{regex.source}/"
	end

	def to_bnf
		to_s
	end
end
