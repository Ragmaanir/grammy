require 'ast'
require 'rules'
require 'log4r'
require 'extensions/hash'

class Grammar
	include Log4r

	attr_accessor :name, :line_number
	attr_reader :rules, :logger

	def initialize(*args,&block)
		@name = args.shift if [Symbol,String].include?(args.first.class)
		options = args.first || {}
		@logger = options[:logger]

		@rules = {}
		
		unless @logger
			@logger = Log4r::Logger.new 'grammy'
			outputter = Log4r::Outputter.stdout
			outputter.formatter = PatternFormatter.new :pattern => "%l - %x %m"
			@logger.outputters = outputter
			@logger.level = WARN
		end

		#begin
			use_dsl do
				instance_exec(&block)
			end
		#rescue Exception => e
		#	# TODO debug only
		#	puts e
		#	puts e.backtrace
		#	raise e
		#end
	end

	# only use DSL in the block
	def use_dsl(&block)
		self.class.send(:include,DSL)

		Symbol.send(:include,Operators)
		String.send(:include,Operators)
		Range.send(:include,Operators)

		begin
			yield
		ensure
			Operators.exclude(Symbol)
			Operators.exclude(Range)
			Operators.exclude(String)
		end
	end

	# These methods are used to define rules.
	module DSL

		include Grammy::Rules

		def rule(options)
			name,defn = options.shift

			options = options.with_default(
				using_skipper: true,
				merging_nodes: false,
				generating_ast: true,
				debug: :all,
				type: :rule
			)

			rule = Rule.to_rule(defn)

			rule.grammar = self

			rule.setup(name,options)
			raise "duplicate rule #{name}" if @rules[name]
			#@logger.warn("duplicate rule #{name}") if @rules[name]
			@rules[name] = rule
		end

		# no parameters passed => returns the skipper
		# options passed => creates and registers a skipper
		def skipper(options={})
			if options == {}
				@skipper
			else
				@skipper = rule(options.with_default(debug: :root_only).merge(using_skipper: false, generating_ast: false, type: :skipper))
			end
		end

		# creates a rule with these options:
		# - does not use skipper
		# - merges nodes
		def token(options)
			rule(options.with_default(debug: :root_only).merge(using_skipper: false, merging_nodes: false, type: :token))
		end

		# generates no extra AST-node
		def helper(options)
			rule(options.merge(merging_nodes: true, type: :helper))
		end

		# Create a rule which does not use a skipper and creates mergeable AST-nodes.
		# This can be used to decompose a token into smaller fragments.
		def fragment(options)
			rule(options.with_default(debug: :none).merge(merging_nodes: true, using_skipper: false, type: :fragment))
		end

		def start(options)
			@start_rule = rule(options)
		end

		def list(rule,sep=',',options={})
			raise unless rule.is_a? Symbol
			range = options[:range] || 0..1000
			result = rule >> (sep >> rule)*range
			# TODO store AST nodes in a list?
			result
		end

		def list?(*params)
			name = "list_helper_#{params.first}".to_sym
			rule(name => list(*params))
			RuleWrapper.new(name,optional: true)
		end

		def eos
			EOSRule.new
		end

	end

	def validate
		raise NotImplementedError # TODO implement
		# check for always fail		: ~:a >> :a
		# check for left recursion: x: :x | :y
		# check that tokens are not nested
	end

	# Stores the result of a call to Grammar#parse.
	# start_pos, end_pos: start and end position of the matched string in the stream # TODO start_pos always == 0?
	# tree: the generated AST
	# errors: list of errors that occurred during parsing
	# match: returns the type of match: :full, :partial, :none
	class ParseResult
		attr_reader :start_pos, :end_pos, :tree, :errors
		
		def initialize(match,context)
			raise unless match.is_a? Grammy::MatchResult
			@result = match.success?
			@start_pos, @end_pos = match.start_pos, match.end_pos
			@tree = match.ast_node
			@stream = context.stream
			@errors = context.errors
		end

		def full_match?
			match == :full
		end

		def partial_match?
			match == :partial
		end

		def no_match?
			match == :none
		end

		def has_errors?
			@errors.any?
		end

		def match
			if @result and @end_pos == @stream.length then :full
			elsif @result then :partial
			else
				:none
			end
		end

		def to_s
			<<-STR.gsub(/^\s+/,'')
			----- RESULT -----
			Match: #{match.to_s}, range: #{@start_pos}-#{@end_pos}
			Errors(#{errors.length}):
			#{errors.map(&:to_s).join}
			STR
		end
	end

	# stream: must behave like a string
	# options:
	# - rule: the name(symbol) of the rule to start parsing with, default is the start rule
	# - debug: true for extra debug output, default is false
	def parse(stream,options={})
		raise("no start rule supplied") unless @start_rule || options[:rule]
		rule = @start_rule
		rule = @rules[options[:rule]] || raise("rule '#{options[:rule]}' not found") if options[:rule]
		logger.level = DEBUG if options[:debug]

		logger.debug("##### Parsing(#{options[:rule]}): #{stream.inspect}")

		context = Grammy::ParseContext.new(self,nil,stream)

		begin
			match = rule.match(context)
		rescue Exception => e
			# TODO debug only
			puts e
			puts e.backtrace
			Log4r::NDC.clear
			logger.level = WARN if options[:debug]
			raise e
		end
		
		result = ParseResult.new(match,context)
		logger.debug("##### success: #{result.match}")

		logger.level = WARN if options[:debug]

		if options[:debug]
			puts result
			result.tree.to_image('debug_'+@start_rule.name)
		end
		result
	end

	# shortcut for:
	#		parse('...',debug: true)
	def parse!(stream,options={})
		parse(stream,options.merge(debug: true))
	end
	
end
