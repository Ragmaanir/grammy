require 'grammar'

module Grammy

	Version = '0.0.3'

	def self.define(name,&block)
		raise unless name.is_a? Symbol
		Grammar.new(name,&block)
	end
	
end