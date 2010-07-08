require 'grammar'
require 'ast_walker'

module Grammy

	def self.define(*args,&block)
		Grammar.new(*args,&block)
	end
	
end
