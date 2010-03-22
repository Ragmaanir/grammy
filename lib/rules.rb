require 'lib/ast'

class Grammy
	module Rules

		module Operators
			def >>(other)
				Sequence.new(nil,[self,other], merge: true)
			end

			def |(other)
				Alternatives.new(nil,[self,other], merge: true)
			end
			
			def *(times)
				times = times..times unless times.is_a? Range
				Repetition.new(nil,self,times: times, merge: true)
			end
		end

		# RULE
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

			def helper?
				(@options[:merge] || !name)
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

			def merge(children)
				raise unless children.is_a? Array
				result = []

				children.each { |node|
					if node.is_a? String and result.last.is_a? String
						result.last << node
					else
						result << node
					end
				}

				result
			end

			def match_element(elem,stream,start_pos)
				#puts "#{rule_type}.match_element(#{elem},_,#{start_pos})"
				case elem
					when Rule
						result = elem.match(stream,start_pos)
						[result,result.match_range]
					when Symbol
						result = grammar.rules[elem].match(stream,start_pos)
						[result,result.match_range]
					when String
						range = start_pos...(start_pos+elem.length)
						str = stream[range]
						# TODO add ability to create custom node MyNode < Node
						#AST::Node.new(nil, children: elem, match_range: range) if elem == str
						[elem,range] if elem == str
					else
						raise "#{rule_type}.match_element type error for: '#{elem}'"
				end
			end

		end

		# SEQUENCE
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

				failed = @sequence.find { |e|
					result,match_range = match_element(e,stream,cur_pos)
					if result
						if result.is_a? Array
							nodes = nodes + result
						else
							nodes << result
						end
						
						cur_pos = match_range.end
					end

					:exit if not result
				}

				if failed
					puts "-> failed"
				else
					puts "-> success"
				end

				# TODO add ability to create custom node MyNode < Node
				#AST::Node.new(name, children: children, match_range: start_pos..cur_pos) unless failed
				if not failed
					if helper?
						nodes
					else
						AST::Node.new(name, children: nodes, match_range: start_pos..cur_pos)
					end
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
							Alternatives.new(nil,r,merge: true)
						when Rule,String,Symbol
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
				node = nil
				result = @alternatives.find { |e|
					node = match_element(e,stream,start_pos)
				}

				if result
					puts "-> matched '#{result}', match_range: #{node.match_range}"
				else
					puts "-> failed"
				end

				# TODO add ability to create custom node MyNode < Node
				#AST::Node.new(name, children: nodes, match_range: start_pos..(node.match_range.end)) if result
				if result
					if merge?
						node
					else
						AST::Node.new(name, children: [node], match_range: start_pos..(node.match_range.end))
					end
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

				nodes = []

				print "#{rule_type}.match(#{stream},#{start_pos})"

				while not failed and nodes.length < repetitions.max
					node = match_element(@rule,stream,cur_pos)
					if node
						nodes << node
						cur_pos = node.match_range.end
					else
						failed = true
					end
				end

				if repetitions.include? nodes.length
					puts "-> success: #{nodes.length} repetitions"
				else
					puts "-> failed"
				end

				if merge?
					nodes = nodes.map{ |n|
						n.children
					}.flatten
					nodes = merge(nodes)
				end

				# TODO add ability to create custom node MyNode < Node
				AST::Node.new(name, children: nodes, match_range: (start_pos..cur_pos)) if repetitions.include? nodes.length
			end
		end

	end # module Rules
end # class Grammy
