require 'ast'
require 'rules'

class Grammar
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
					rule = Sequence.new(name,[defn],options)
				when Symbol
					#raise "empty rule: #{name}"
					puts "warning: empty rule '#{name}'"
					rule = @rules[name] || raise("rule '#{defn}' not found in rule '#{name}'")
				when Rule
					rule = defn
			else
				raise "invalid rule definition type: '#{defn.class}'"
			end

			rule.grammar = self
			rule.name = name
			rule.helper = options[:helper] || false
			raise "duplicate rule #{name}" if @rules[name]
			@rules[name] = rule
		end

		def helper(options)
			rule(options.merge(helper: true))
		end

	end

	include DSL

	def parse(stream,options)
		rule = @rules[options[:rule]] || raise("rule '#{options[:rule]}' not found")

		begin
			tree = rule.match(stream,0)
		rescue Exception => e
			puts e
			puts e.backtrace
		end
		
		tree = rule.match(stream,0)
		tree
	end
	
end
