require 'lib/ast'

class Grammy
	module Rules

		module Operators
			def >>(other)
				if other.is_a? Sequence and other.helper?
					Sequence.new(nil,[self]+other.sequence, helper: true)
				else
					Sequence.new(nil,[self,other], helper: true)
				end
			end

			def |(other)
				Alternatives.new(nil,[self,other], helper: true)
			end
			
			def *(times)
				times = times..times unless times.is_a? Range
				if self.is_a? Range
					alt = Alternatives.new(nil,self, helper: true)
					Repetition.new(nil,alt,times: times, helper: true)
				else
					Repetition.new(nil,self,times: times, helper: true)
				end
			end
		end

		#
		# RULE
		#
		class Rule
			include Operators

			attr_accessor :name, :options
			attr_reader :grammar

			def initialize(name,options={})
				@name = name
				@options = options
			end

			def rule_type
				self.class.name.split('::').last
			end

			def helper=(value)
				@options[:helper] = value
			end

			def helper?
				(@options[:helper] || !name)
			end

			def ignore?
				!!@options[:ignore]
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

			def match_element(elem,stream,start_pos)
				#puts "#{rule_type}.match_element('#{elem}','#{stream[start_pos..(-1)]}',#{start_pos})"
				case elem
					when Rule
						elem.match(stream,start_pos)
					when Symbol
						grammar.rules[elem].match(stream,start_pos)
					when String
						range = start_pos..(start_pos+(elem.length-1))
						# TODO add ability to create custom node MyNode < Node
						AST::Node.new(:_str, match_range: range, merge: true, stream: stream) if elem == stream[range]
					else
						raise "#{rule_type}.match_element type error for: '#{elem}'"
				end
			end

		end

		#
		# SEQUENCE
		#
		class Sequence < Rule
			def initialize(name,seq,options={})
				raise "seq.class must be in [Symbol,Rule,Array,String]" unless [Symbol,Rule,Array,String].member? seq.class
				@sequence = seq
				super(name,options)
			end

			def children
				@sequence
			end

			def match(stream,start_pos)
				nodes = []
				cur_pos = start_pos

				print "#{rule_type}.match(#{stream},#{start_pos})"

				# TODO add ability to create custom node MyNode < Node
				node = AST::Node.new(name, merge: helper?, stream: stream)

				failed = @sequence.find { |e|
					result = match_element(e,stream,cur_pos)
					if result
						nodes << result
						
						cur_pos = result.match_range.end + 1
					end

					:exit if not result
				}

				if failed
					puts "-> failed"
				else
					puts "-> success"
				end

				unless failed
					nodes.each{|n| node.add_child(n) }
					node.match_range = start_pos..(cur_pos-1)
					node
				end
			end
		end

		# ALTERNATIVE
		class Alternatives < Rule
			def initialize(name,alts,options={})
				raise "alts.class must be in [Symbol,Rule,Array,Range]" unless [Symbol,Rule,Array,Range].member? alts.class

				@alternatives = alts.map{|r|
					case r
						when Range, Array
							Alternatives.new(nil,r,helper: true)
						when Rule,String,Symbol,Integer
							r
					else
						raise "invalid type: #{r}"
					end
				}
				super(name,options)
			end

			def children
				@alternatives
			end

			def match(stream,start_pos)
				print "#{rule_type}.match('#{stream}',#{start_pos})"
				result = nil
				# TODO add ability to create custom node MyNode < Node
				node = AST::Node.new(name, merge: helper?, stream: stream)
				
				success = @alternatives.find { |e|
					result = match_element(e,stream,start_pos)
				}

				if success
					puts "-> matched '#{success}', match_range: #{result.match_range}"
				else
					puts "-> failed"
				end
				
				if success
					node.add_child(result)
					node.match_range = result.match_range
					node
				end
			end
		end

		# REPETITION
		class Repetition < Rule
			def initialize(name,rule,options={})
				#raise "rule.class must be in [Symbol,Rule,Array,String]" unless [Symbol,Rule,Array,Range].member? alts.class
				raise "rule must be a rule, symbol or range" unless rule.kind_of? Rule or [Symbol,Range,String].include? rule.class
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
				failed = false
				cur_pos = start_pos

				# TODO add ability to create custom node MyNode < Node
				node = AST::Node.new(name, merge: helper?, stream: stream)
				nodes = []

				print "#{rule_type}.match(#{stream},#{start_pos})"

				while not failed and nodes.length < repetitions.max
					result = match_element(@rule,stream,cur_pos)

					if result
						nodes << result
						
						cur_pos = result.match_range.end + 1
					else
						failed = true
					end
				end

				if repetitions.include? nodes.length
					puts "-> success: #{nodes.length} repetitions"
				else
					puts "-> failed"
				end
				
				if repetitions.include? nodes.length
					nodes.each{|n| node.add_child(n) }
					node.match_range = start_pos..(cur_pos-1) # TODO compute when adding children?
					node
				end
			end
		end

	end # module Rules
end # class Grammy
