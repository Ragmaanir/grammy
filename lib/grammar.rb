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
			instance_exec(&block)
		rescue Exception => e
			puts e
			puts e.backtrace
			raise e
		end
	end

	module DSL

		include Grammy::Rules

		Symbol.__send__(:include,Operators)
		String.__send__(:include,Operators)
		Range.__send__(:include,Operators)

		def rule(options)
			name,defn = options.shift

			rule = Rule.to_rule(defn)

			rule.grammar = self
			rule.name = name
			rule.helper = options[:helper] || false
			raise "duplicate rule #{name}" if @rules[name]
			@rules[name] = rule
		end

		def helper(options)
			rule(options.merge(helper: true))
		end

		def start(options)
			@start_rule = rule(options)
		end

	end

	include DSL

	def debug!
		@logger.level = DEBUG
	end

	def parse(stream,options={})
		raise("no start rule supplied") unless @start_rule || options[:rule]
		rule = @start_rule
		rule = @rules[options[:rule]] || raise("rule '#{options[:rule]}' not found") if options[:rule]

		logger.debug("##### Parsing(#{options[:rule]}): \"#{stream}\"")

		begin
			match = rule.match(stream,0)
		rescue Exception => e
			puts e
			puts e.backtrace
		end

		logger.debug("##### success: #{match.success?}")

		match
	end
	
end
