
module Grammy
	module Rules

		MAX_REPETITIONS = 10_000

		# Special operators used in the Grammar DSL.
		# The module is designed to be removable so the extra operators
		# wont pollute String, Symbol and Range.
		module Operators

			# includes the module so that it can be removed later with #exclude
			def self.included(target)
				# create a clone of the module so the methods can be removed from the
				# clone without affecting the original module
				cloned_mod = self.clone
				my_mod_name = name

				# store the module clone that is included
				target.class_eval {
					@@removable_modules ||= {}
					@@removable_modules[my_mod_name] = cloned_mod
				}

				# make backup of already defined methods
				cloned_mod.instance_methods.each {|imeth|
					if target.instance_methods.include? imeth
						target.send(:alias_method,"__#{imeth}_backup",imeth)
					end
				}

				cloned_mod.send(:append_features,target)
			end

			# removes the module from the target by
			# removing added methods and aliasing the backup
			# methods with their original name
			def self.exclude(target)
				# get the module
				mod = target.send(:class_eval){
					@@removable_modules
				}[name] || raise("module '#{name}' not found in internal hash, cant exclude it")

				# remove / restore the methods
				mod.instance_methods.each {|imeth|
					mod.send(:undef_method,imeth)

					if target.instance_methods.include? "__#{imeth}_backup"
						target.send(:alias_method,imeth,"__#{imeth}_backup")
						target.send(:undef_method,"__#{imeth}_backup")
					end
				}
			end

			def &(right)
				right = Rule.to_rule(right)
				right.backtracking = false
				Sequence.new(nil,[self,right], helper: true)
			end

			def >>(other)
				Sequence.new(nil,[self,other], helper: true)
			end

			def |(other)
				Alternatives.new(nil,[self,other], helper: true)
			end

			def *(times)
				times = times..times if times.is_a? Integer
				raise("times must be a range or int but was: '#{times}'") unless times.is_a? Range

				Repetition.new(nil,Rule.to_rule(self),times: times, helper: true)
			end

			def +@
				Repetition.new(nil,self,times: 1..MAX_REPETITIONS, helper: true)
			end

			def ~@
				Repetition.new(nil,self,times: 0..MAX_REPETITIONS, helper: true)
			end
		end

		#
		# RULE
		#
		class Rule
			include Operators

			attr_accessor :name, :options, :parent
			attr_reader :grammar
			attr_writer :helper, :backtracking, :skipping, :ignored

			def initialize(name,options={})
				@name = name
				@helper = options.delete(:helper)
				@backtracking = options.delete(:backtracking)
				@skipping = options.delete(:skipping)
				@ignored = options.delete(:ignored)
				@options = options
			end

			def root
				cur_rule = self
				while cur_rule.parent
					cur_rule = cur_rule.parent
				end

				cur_rule
			end

			# For debugging purposes: returns the classname
			def rule_type
				self.class.name.split('::').last
			end

			# true iff this rule is a helper rule. a rule is automatically a helper rule when it has no name.
			# a helper rule generates no AST::Node
			def helper?
				(@helper || !name)
			end

			def backtracking?
				@backtracking != false
			end

			def skipping?
				grammar.skipper and @skipping
			end

			# true when the matched string should not be part of the generated AST (like ',' or '(')
			def ignored?
				@ignored #@options[:ignored]
			end

			def children
				raise NotImplementedError
			end

			def grammar=(gr)
				raise unless gr.is_a? Grammar
				@grammar = gr
				children.each{|rule|
					rule.grammar= gr if rule.kind_of? Rule
				}
			end

			def create_ast_node(context,range)
				AST::Node.new(name, merge: helper?, range: range, stream: context.stream)
			end

			def skip(context)
				grammar.skipper.match(context)
			end

			def match(context)
				raise NotImplementedError
			end

			def self.to_rule(input)
				case input
				when Range then RangeRule.new(:_range,input,helper: true)
				when Array then Alternatives.new(nil,input, helper: true)
				when Symbol then RuleWrapper.new(input,helper: true)
				when String then StringRule.new(input,helper: true)
				when Integer then StringRule.new(input.to_s,helper: true)
				when Rule then input
				else
					raise "invalid input '#{input}', cant convert to a rule"
				end
			end

			def to_s
				rule_type + '{' + children.join(',') + '}'
			end

			def to_image(name)
				raise NotImplementedError
				require 'graphviz'
				graph = GraphViz.new(name)
				graph.node[shape: :box, fontsize: 8]

				to_image_impl(graph)
			end

			def debug_start(context)
				abbr = case rule_type
					when "RuleWrapper" then "Wrp"
					else rule_type[0,3]
				end

				scope_name = name || ':'+abbr
				scope_name = '|>' if self.class == RuleWrapper
				Log4r::NDC.push(scope_name)
				start = context.position
				grammar.logger.debug("#{abbr}.match(#{context.stream[start,15].inspect},#{start})")
			end

			def debug_end(match)
				data = match.ast_node.data if match.ast_node
				result = match.success? ? "SUCCESS" : "FAIL"
				grammar.logger.debug("--> #{result} => #{data.inspect},#{match.start_pos}..#{match.end_pos}")
				Log4r::NDC.pop
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