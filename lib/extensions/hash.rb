
class Hash

	# returns a hash that contains only the supplied keys
	def only(*keys)
		self.select{ |key,_| keys.include? key }
	end
	
	# returns the values for the supplied keys (in the order of the keys in the array)
	def slice(*keys)
		res = []
		keys.each{ |key| res << self[key] if has_key?(key) }
		res
	end
	
	def except(*keys)
		dup.except!(*keys)
	end
	
	def except!(*keys)
		keys.each{ |key| delete(key) }
		self
	end

	def extract!(*keys)
		result = self.only(*keys)
		self.delete_if{|key,_| keys.include? key }
		result
	end

	def with_default(hash)
		#hash.merge(self) # error: does not keep order
		copy = dup
		hash.each { |k,v| copy[k] = v unless copy.has_key?(k) }
		copy
	end
	
	def map_keys(&block)
		res = {}
		self.each { |k,v| res.merge!(block.call(k) => v)}
		res
	end
	
	def symbolize_keys
		map_keys(&:to_sym)
	end
	
	def map_hash(&block)
		res = {}
		self.each { |k,v| res.merge!(block.call(k,v)) }
		res
	end
	
	def map_values(&block)
		res = {}
		self.each { |k,v| res.merge!(k => block.call(k,v)) }
		res
	end

end
