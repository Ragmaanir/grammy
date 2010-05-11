
class Hash

	def only(*keys)
		self.select{ |key,_| keys.include? key }
	end

	alias :slice :only

	def extract!(*keys)
		result = self.only(*keys)
		self.delete_if{|key,_| keys.include? key }
		result
	end

	def with_default(hash)
		#hash.merge(self) # error: does not keep order
		copy = dup
		hash.each { |k,v| copy[k] = v unless copy[k]!=nil }
		copy
	end

end