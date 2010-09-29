
require 'pathname'
gem 'rspec'

require 'Grammy'

# require custom matchers
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

class CleverBacktraceTweaker < Spec::Runner::BacktraceTweaker

	PROJECT_PATH = Pathname.new(__FILE__).dirname.parent

	DEFAULT_IGNORE_PATTERNS = [
		/[0-9\.]+\/gems\/rspec/,
		/\/lib\/ruby\/[0-9\.]+\//
	]
	
	DEFAULT_ABBREVIATION_PATTERNS = {
		/#{PROJECT_PATH}\/lib(\/.*)/ => "LIB: #1",
		/#{PROJECT_PATH}\/spec(\/.*)/ => "SPEC: #1",
		/\/gems\/([^0-9\/][^\/]+)(\/.*)/ => "#1: #2"
	}

	def initialize(*patterns)
		super
		@abbreviation_patterns = DEFAULT_ABBREVIATION_PATTERNS
		ignore_patterns(DEFAULT_IGNORE_PATTERNS)
		ignore_patterns(*patterns)
	end

	def ignore_patterns(*patterns)
		@ignore_patterns += patterns.flatten.map { |pattern| Regexp.new(pattern) }
	end

	def ignored_patterns
		@ignore_patterns
	end
	
	def abbreviation_patterns
		@abbreviation_patterns
	end
	
	def abbreviation_pattern(patterns)
		raise unless patterns.is_a? Hash
		@abbreviation_patterns.merge!(patterns)
	end
	
	def simplify_backtrace_entry(entry)
		if item = abbreviation_patterns.find{|patt,_| patt === entry}
			patt,abbrev = *item
			
			matches = patt.match(entry)
			
			matches[1,matches.length].each_with_index { |match,i|
				abbrev = abbrev.sub("##{i+1}",match)
			}
			
			abbrev
		else
			entry
		end
	end
	
	def tweak_backtrace(error)
		return if error.backtrace.nil?
		
		tweaked = error.backtrace.inject([]) do |trace,message|
			clean_up_double_slashes(message)
			
			if ignored_patterns.any?{|pattern| pattern === message.strip }
				trace << nil unless trace.last == nil
			else
				trace << simplify_backtrace_entry(message)
			end
			
			trace
		end
		
		tweaked = tweaked.map{ |message| message || "---skipped---" }
		
		error.set_backtrace(tweaked)
	end
end

Spec::Runner.options.backtrace_tweaker = CleverBacktraceTweaker.new
