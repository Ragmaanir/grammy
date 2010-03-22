require 'lib/ast'
require 'lib/rules'

class Grammar
	def self.define(name,&block)
		Grammar.new(name,&block)
	end

	attr_accessor :name
	attr_reader :rules

	def initialize(name,&block)
		@name = name
		@rules = {}
		
		instance_exec(&block)
	end

	module DSL

		include Grammy::Rules

		Symbol.__send__(:include,Operators)
		String.__send__(:include,Operators)
		Range.__send__(:include,Operators)

		def rule(options)
			name,defn = options.shift
			
			case defn
				when Range
					rule = Alternatives.new(name,defn.to_a,options)
				when Array
					rule = Alternatives.new(name,defn,options)
				when String
					rule = Sequence.new(name,[defn],{ignore: true}.merge(options))
				when Symbol
					raise "empty rule"
				when Rule
					rule = defn
			else
				raise "invalid rule definition type: '#{defn.class}'"
			end

			rule.grammar = self
			rule.name = name
			raise "duplicate rule #{name}" if @rules[name]
			@rules[name] = rule
		end

		def helper(options)
			options = options.merge(merge: true)
			rule(options)
		end

	end

	include DSL

	def parse(stream,options)
		#stream = StringStream.new(stream) if stream.is_a? String
		rule = @rules[options[:rule]]

		tree = rule.match(stream,0)
		tree.stream = stream
		tree
	end

end
