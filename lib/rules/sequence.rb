require 'rules/rule'

module Grammy
	module Rules

		#
		# SEQUENCE
		#
		class Sequence < Rule
			attr_reader :children

			def initialize(name,seq,options={})
				super(name,options)
				seq = seq.map{|elem| Rule.to_rule(elem) }

				seq = seq.map{|elem|
					if elem.is_a? Sequence and elem.anonymous?
						if not elem.backtracking?
							elem.children.first.backtracking = false
						end
						elem.children
					else
						elem
					end
				}.flatten

				@children = seq

				@children.each{|c| c.parent = self }
			end

			def match(context)
				debug_start(context)

				results = [] # will store the MatchResult of each rule of the sequence
				start_pos = context.position
				do_backtracking = true

				# --find the first rule in the sequence that fails to match the input
				# - add the results of all succeeding rules to the match_results array
				failed = @children.find { |e|
					skip(context) if using_skipper?
					match = e.match(context)
					do_backtracking &&= e.backtracking?

					context.set_backtrack_border! unless do_backtracking

					if match.success?
						results << match
					else
						if do_backtracking
							context.position = start_pos
						else
							context.add_error(root,e) # TODO ERROR + continue
						end
					end

					:exit if match.failure? # end loop
				}

				end_pos = context.position

				if generating_ast?
					children = results.map{|res| res.ast_node }.compact
					node = create_ast_node(context,[start_pos,end_pos],children)
				end

				result = MatchResult.new(self,!failed,node,start_pos,end_pos)
				result.backtracking = do_backtracking

				debug_end(context,result)
				result
			end

			def to_s
				@children.map{|item|
					if item.is_a? Alternatives
						"(#{item})"
					else
						item.to_s
					end
				}.join(" >> ")
			end

			def to_bnf
				@children.map{|item|
					if item.is_a? Alternatives
						"(#{item})"
					else
						item.to_bnf
					end
				}.join(" ")
			end

			protected
			def to_image_impl(graph)
				raise NotImplementedError # TODO implement
				#
				# Problem: a >> +(b | c)
				# How to display that?
				#
				#    +-----<-----+
				#    |  +--b--+  |
				# a--+--|     |--+-->
				#       +--c--+
				#
				#
				raise "no graph supplied" unless graph
				last_node = nil
				@children.each{|item|
					new_node = graph.add_node(cur_node.data.object_id.to_s, label: "'#{cur_node.data}'")
					new_node[shape: :circle, style: :filled, fillcolor: "#6699ff", fontsize: 8]
					graph.add_edge(last_node,new_node)
				}
			end

		end # Sequence

	end # Rules
end # Grammy