
require 'rules/operators'

module Grammy
	module Rules

		#
		# RULE
		#
		class Rule
			include Operators

			Callbacks = [:modify_ast,:on_error,:on_match]
			Options = [:backtracking,:using_skipper,:merging_nodes,:generating_ast,:debug,:type,:times,:optional] + Callbacks
			DebugModes = [:like_root,:all,:root_only,:none]

			attr_accessor :name, :parent
			attr_reader :grammar, :options, :debug, :type
			attr_writer :backtracking

			def initialize(name,options={})
				setup(name,options)
			end

			def setup(name,options={})
				@name = name

				unsupported = options.reject{ |key,_| Options.include? key }
				raise "unsupported keys: #{unsupported.inspect}" if unsupported.any?

				options = options.with_default(
					backtracking: true,
					using_skipper: false,
					debug: :like_root,
					type: :anonymous,
					merging_nodes: true,
					generating_ast: true
				)
				
				@callbacks = options.extract!(*Callbacks)

				@merging_nodes = options.delete(:merging_nodes)
				@generating_ast = options.delete(:generating_ast)
				@backtracking = options.delete(:backtracking)
				@using_skipper = options.delete(:using_skipper)
				
				@debug = options.delete(:debug)
				@type = options.delete(:type)
				@options = options

				raise "@merging_nodes was #{@merging_nodes.inspect}" unless [true,false].include? @merging_nodes
				raise "invalid debug mode: #{@debug.inspect}" unless DebugModes.include? @debug
				raise unless [true,false].include? @generating_ast
			end

			# The #root method returns the production that the rule is part of.
			# 
			# *Example*
			# for the rule:
			#		rule x: :a >> +'x'
			# the following
			#		x.children[1].children[0].root
			# returns x
			def root
				cur_rule = self
				while cur_rule.parent
					cur_rule = cur_rule.parent
				end

				cur_rule
			end

			def anonymous?
				!@name
			end

			# Returns true iff debugging is turned on for this rule.
			# The method takes into account the setting for the root of the rule:
			# - when the debug mode of the root rule is set to :all, then all subrules have debugging turned on
			# - when the debug mode of the root rule is set to :root_only, then only the root rule has debugging turned on
			def debugging?
				if root.debug == :all
					true
				elsif root.debug == :root_only
					root == self
				else
					false
				end
			end

			# TODO needed?
			def type
				result = @type || root.type
				raise unless [:anonymous,:rule,:token,:fragment,:skipper].include? result
				result
			end

			# For debugging purposes: returns the classname
			def class_name
				self.class.name.split('::').last
			end

			# TRUE iff the node generated by this rule should be mergeable with nodes of the same type.
			# Used to store token text in one node.
			def merging_nodes?
				@merging_nodes
			end

			def backtracking?
				raise unless [true,false].include? @backtracking
				@backtracking
			end

			def using_skipper?
				grammar.skipper and (@using_skipper or (root.using_skipper? unless root==self))
			end

			def generating_ast?
				@generating_ast
			end

			def children
				raise NotImplementedError
			end

			def grammar=(gr)
				raise unless gr.is_a? Grammar
				@grammar = gr
				children.each{|child|
					child.grammar= gr if child.kind_of? Rule
				}
			end

			def create_ast_node(context,range,children=[])
				node = AST::Node.new(name, merge: merging_nodes?, range: range, stream: context.stream, children: children)
				modify_node(node)
			end

			# apply callback to node
			def modify_node(node)
				if @callbacks[:modify_ast]
					node = @callbacks[:modify_ast].call(node)
				end
				node
			end

			def skip(context)
				grammar.skipper.match(context)
			end

			def match(context)
				raise NotImplementedError
			end

			def self.to_rule(input)
				case input
				when Range then RangeRule.new(nil,input)
				when Array then Alternatives.new(nil,input)
				when Symbol then RuleWrapper.new(input)
				when String then StringRule.new(input)
				when Integer then StringRule.new(input.to_s)
				when Rule then input
				else
					raise "invalid input '#{input}', cant convert to a rule"
				end
			end

			def to_s
				class_name + '{' + children.join(',') + '}'
			end

			def to_image(name)
				raise NotImplementedError
				require 'graphviz'
				graph = GraphViz.new(name)
				graph.node[shape: :box, fontsize: 8]

				to_image_impl(graph)
			end

			def rule_class_name_abbreviation
				case class_name
					when "RuleWrapper" then "Wrp"
					else class_name[0,3]
				end
			end

			def debug_scope_name
				abbr = rule_class_name_abbreviation

				scope_name = name || ':'+abbr
				#scope_name = '>' if self.class == RuleWrapper
				scope_name
			end

			def debug_start(context)
				Log4r::NDC.push(debug_scope_name) if self.class != RuleWrapper
				#start = context.position
				#grammar.logger.debug("match(#{context.stream[start,15].inspect},#{start})") if debugging?
			end

			def debug_end(context,match)
				consumed = context.stream[match.start_pos,match.length]
				range = match.start_pos..match.end_pos

				result = match.success? ? "SUCC" : "FAIL"
				grammar.logger.debug("\t\t #{result}[#{range}]: #{consumed.inspect}") if debugging?
				Log4r::NDC.pop if self.class != RuleWrapper
			end
		end

		#
		# LeafRule
		# - just a helper class
		class LeafRule < Rule
			def children
				[]
			end
		end

	end # Rules
end # Grammy