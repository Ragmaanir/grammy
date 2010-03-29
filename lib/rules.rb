require 'ast'
require 'match_result'

module Grammy
	module Rules

		MAX_REPETITIONS = 10_000

		module Operators

			def self.included(target)
				cloned_mod = self.clone
				my_mod_name = name

				# store the module that is included
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
		end

		#
		# RULE
		#
		class Rule
			include Operators

			SourceTypes = [Rule,Array,Range,String,Integer,Symbol]

			attr_accessor :name, :options
			attr_reader :grammar

			def initialize(name,options={})
				@name = name
				@options = options
			end

			# For debugging purposes: returns the classname
			def rule_type
				self.class.name.split('::').last
			end

			def helper=(value)
				@options[:helper] = value
			end

			# true iff this rule is a helper rule. a rule is automatically a helper rule when it has no name.
			# a helper rule generates no AST::Node
			def helper?
				(@options[:helper] || !name)
			end

			def skipping=(value)
				raise "invalid skipping value: '#{value}'" unless [true,false].include? value
				@options[:skipping] = value
			end

			def skipping?
				grammar.skipper and @options[:skipping]
			end

			def ignored=value
				raise unless [true,false].member? value
				@options[:ignored] = value
			end

			# true when the matched string should not be part of the generated AST (like ',' or '(')
			def ignored?
				@options[:ignored]
			end

			def children
				raise "not implemented in #{self.class}"
			end

			def grammar=(gr)
				raise unless gr.is_a? Grammar
				@grammar = gr
				children.each{|rule|
					rule.grammar= gr if rule.kind_of? Rule
				}
			end

			def skip(stream,start)
				match = grammar.skipper.match(stream,start)
				
				if match.success?
					match.match_range.end + 1
				else
					match.match_range.begin
				end
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

			def debug_start(stream,start)
				str = case rule_type
					when "Sequence" then "Seq"
					when "Alternatives" then "Alt"
					when "RangeRule" then "Ran"
					when "RuleWrapper" then "Wrp"
					when "StringRule" then "Str"
					when "Repetition" then "Rep"
					else raise
				end


				Log4r::NDC.push(name || ':'+str)
				grammar.logger.debug("#{str}.match(#{stream[start..-1].inspect},#{start})")
			end

			def debug_end(match)
				data = match.ast_node.data if match.ast_node
				grammar.logger.debug("--> success: #{match.success?} => #{data.inspect},#{match.match_range}")
				Log4r::NDC.pop
			end
		end

		#
		# RangeRule
		#
		class RangeRule < Rule
			def initialize(name,range,options={})
				super(name,options)
				raise "range must be range but was: '#{range}'" unless range.is_a? Range
				@range = range
			end

			def range
				@range
			end

			def children
				[]
			end

			def match(stream,start_pos)
				debug_start(stream,start_pos)
				success = false
				range = start_pos..start_pos

				matched_element = @range.find { |e|
					range = start_pos..(start_pos+(e.length-1))
					success = (e == stream[range])
				}

				range = start_pos..start_pos unless success

				node = AST::Node.new(name, match_range: range, merge: helper?, stream: stream) if success and not ignored?
				match = MatchResult.new(self,success,node,range)
				debug_end(match)
				match
			end
		end

		#
		# StringRule
		# 
		class StringRule < Rule
			def initialize(string,options={})
				super(nil,options)
				raise unless string.is_a? String
				@string = string
			end

			def string
				@string
			end

			def children
				[]
			end

			def match(stream,start_pos)
				debug_start(stream,start_pos)
				range = start_pos..(start_pos+(@string.length-1))
				success = (@string == stream[range])
				range = start_pos..start_pos unless success
				
				node = AST::Node.new(name || :_str, match_range: range, merge: helper?, stream: stream) if success and not ignored?
				match = MatchResult.new(self,success,node,range)

				debug_end(match)
				match
			end
		end

		#
		# RULE WRAPPER rule
		# Wraps a symbol which represents another rule which may be not defined yet.
		# When the symbol ends with '?', then the rule is optional
		class RuleWrapper < Rule
			def initialize(sym,options={})
				super(nil,options) # FIXME pass the name?
				raise("sym has to be a symbol but was: '#{sym}'") unless sym.is_a? Symbol
				@optional = false
				if sym[-1]=='?'
					@optional = true
					sym = sym[0..-2].to_sym
				end
				@symbol = sym
			end

			def name
				#rule.name
				@symbol
			end

			def optional?
				@optional
			end

			def grammar=(gr)
				# dont set grammar for children because the wrapped rule might not be defined yet
				@grammar = gr
			end

			def children
				rule.children
			end

			def rule
				grammar.rules[@symbol] || raise("RuleWrapper: rule not found '#{@symbol}'")
			end

			def match(stream,start_pos)
				debug_start(stream,start_pos)
				
				match_result = rule.match(stream,start_pos)

				success = match_result.success? || optional?

				# FIXME maybe create an AST Node and store it in match result?
				match = MatchResult.new(self, success, match_result.ast_node, match_result.match_range)
				
				debug_end(match)
				match
			end

		end

		#
		# SEQUENCE
		#
		class Sequence < Rule
			def initialize(name,seq,options={})
				#raise "seq.class must be in #{Rule::SourceTypes} but was #{seq.class}" unless Rule::SourceTypes.member? seq.class
				seq = seq.map{|elem| 
					if elem.is_a? Sequence and elem.helper?
						elem.children
					else
						elem
					end
				}.flatten
				
				seq = seq.map{|elem| Rule.to_rule(elem) }
				@sequence = seq
				super(name,options)
			end

			def children
				@sequence
			end

			def match(stream,start_pos)
				debug_start(stream,start_pos)
				
				match_results = [] # will store the MatchResult of each rule of the sequence
				cur_pos = start_pos

				# --find the first rule in the sequence that fails to match the input
				# - add the results of all succeeding rules to the match_results array
				failed = @sequence.find { |e|
					cur_pos = skip(stream,cur_pos) if skipping?
					match_result = e.match(stream,cur_pos)
					if match_result.success?
						match_results << match_result

						cur_pos = match_result.match_range.end + 1
					end

					:exit if match_result.fail? # end loop
				}

				range = start_pos..(cur_pos-1)

				unless ignored?
					# TODO add ability to create custom node MyNode < Node
					node = AST::Node.new(name, merge: helper?, stream: stream)
					match_results.each{|res| node.add_child(res.ast_node) }
					node.match_range = range #start_pos..(cur_pos-1)
				end

				match = MatchResult.new(self,!failed,node,range)

				debug_end(match)
				match
			end

		end

		# ALTERNATIVE
		class Alternatives < Rule
			def initialize(name,alts,options={})
				#raise "alts.class must be in #{Rule::SourceTypes} but was #{alts.class}" unless Rule::SourceTypes.member? alts.class

				@alternatives = alts.map{|r| Rule.to_rule(r) }
				super(name,options)
			end

			def children
				@alternatives
			end

			def match(stream,start_pos)
				debug_start(stream,start_pos)
				match_result = nil
				other_results = [] # stores all failed matches of other alternatives

				success = @alternatives.find { |e|
					start_pos = skip(stream,start_pos) if skipping?
					match_result = e.match(stream,start_pos)
					other_results << match_result if match_result.fail?
					match_result.success?
				}

				unless ignored?
					# TODO add ability to create custom node MyNode < Node
					node = AST::Node.new(name, merge: helper?, stream: stream)
					node.add_child(match_result.ast_node) if match_result.ast_node
					node.match_range = match_result.match_range
				end

				match = MatchResult.new(self,!!success,node,match_result.match_range)
				debug_end(match)
				match
			end

		end

		# REPETITION
		class Repetition < Rule
			def initialize(name,rule,options={})
				#raise "rule.class must be in [Symbol,Rule,Array,String]" unless [Symbol,Rule,Array,Range].member? alts.class
				#raise "rule must be in #{Rule::SourceTypes} but was #{rule.class}" unless Rule::SourceTypes.include? rule.class
				rule = Rule.to_rule(rule)
				@rule = rule
				super(name,options)
			end

			def children
				[@rule]
			end
			
			def repetitions
				@options[:times]
			end

			def match(stream,start_pos)
				success = false # set to true when repetition in specified range
				failed = false # used for the loop
				cur_pos = start_pos

				
				match_results = []

				debug_start(stream,start_pos)

				while not failed and match_results.length < repetitions.max
					cur_pos = skip(stream,cur_pos) if skipping?
					match_result = @rule.match(stream,cur_pos)

					if match_result.success?
						match_results << match_result

						cur_pos = match_result.match_range.end + 1
					else
						# TODO store failed match?
						failed = true
					end
				end

				success = repetitions.include? match_results.length
				
				unless ignored?
					# TODO add ability to create custom node MyNode < Node
					node = AST::Node.new(name, merge: helper?, stream: stream)
					match_results.each{|res| node.add_child(res.ast_node) }
					node.match_range = start_pos..(cur_pos-1) # TODO compute when adding children?
				end

				match = MatchResult.new(self, !!success, node, start_pos..(cur_pos-1))
				debug_end(match)
				match
			end

		end

	end # module Rules
end # module Grammy
