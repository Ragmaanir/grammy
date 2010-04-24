require 'grammar'

module Grammy

	def self.define(*args,&block)
		Grammar.new(*args,&block)
	end
	
end