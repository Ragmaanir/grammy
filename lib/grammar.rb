require 'ast'
require 'rules'
require 'log4r'

class Grammar
	include Log4r

	attr_accessor :name
	attr_reader :rules, :logger

	def initialize(name,options={},&block)
		@name = name
		@rules = {}
		@logger = options[:logger]
		
		unless @logger
			@logger = Log4r::Logger.new 'grammy'
			outputter = Log4r::Outputter.stdout
			outputter.formatter = PatternFormatter.new :pattern => "%l - %x - %m"
			@logger.outputters = outputter
			@logger.level = WARN
		end

		begin
			use_dsl do
				instance_exec(&block)
			end
		rescue Exception => e
			# TODO debug only
			puts e
			puts e.backtrace
			raise e
		end
	end

	def use_dsl(&block)
		self.class.send(:include,DSL)

		Symbol.send(:include,Operators)
		String.send(:include,Operators)
		Range.send(:include,Operators)

		yield

		Operators.exclude(Symbol)
		Operators.exclude(Range)
		Operators.exclude(String)
	end

	module DSL

		include Grammy::Rules

		def rule(options)
			name,defn = options.shift

			options = {skipping: true, helper: false, ignored: false}.merge(options)

			rule = Rule.to_rule(defn)

			rule.grammar = self
			rule.name = name
			rule.helper = options[:helper] || false
			rule.skipping = options[:skipping]
			rule.ignored = options[:ignored]
			raise "duplicate rule #{name}" if @rules[name]
			@rules[name] = rule
		end

		def skipper(options={})
			if options == {}
				@skipper
			else
				@skipper = helper(options.merge(skipping: false, ignored: true))
			end
		end

		# creates a rule which does not use the skipper
		def token(options)
			rule(options.merge(skipping: false, helper: false))
		end

		# creates a rule with the helper: true option
		# the rule creates mergeable AST nodes, e.g. for letters:
		#		+('a'..'z') #=> creates only one AST node, not one for each letter
		def helper(options)
			rule(options.merge(helper: true))
		end

		def start(options)
			@start_rule = rule(options)
		end

		def list(rule,sep=',',options={})
			range = options[:range] || 0..1000
			result = rule >> (sep >> rule)*range
			# TODO store AST nodes in a list?
			result
		end

	end

	def debug=(value)
		if value
			@logger.level = DEBUG
		else
			@logger.level = WARN
		end
	end

	def validate
		raise "not implemented" # TODO implement
		# check for always fail		: ~:a >> :a
		# check for left recursion: x: :x | :y
		
	end

	def parse(stream,options={})
		raise("no start rule supplied") unless @start_rule || options[:rule]
		rule = @start_rule
		rule = @rules[options[:rule]] || raise("rule '#{options[:rule]}' not found") if options[:rule]
		logger.level = DEBUG if options[:debug]

		logger.debug("##### Parsing(#{options[:rule]}): #{stream.inspect}")

		begin
			match = rule.match(stream,0)
		rescue Exception => e
			# TODO debug only
			puts e
			puts e.backtrace
			raise e
		end

		logger.debug("##### success: #{match.success?}")

		logger.level = WARN if options[:debug]

		match
	end
	
end
