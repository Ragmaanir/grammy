
# extend a module M with this module to make that module M excludable
module ExcludableModule
	module ExclusionTarget
		def exclude(mod)
			mod.excluded(self)
		end
	end
	
	def included(t)
		raise "the module is not meant to be included. inject it instead."
	end
	
	def inject_into(target)
		instance_methods.each do |meth|
			if target.instance_methods.include?(meth)
				target.send(:class_eval) do
					alias_method("__backup_#{meth}",meth)
					#undef_method(meth)
					define_method(meth) do |*args|
						super(*args) #raise 'not overwritten'
					end
				end
			end
		end
		
		append_features(target)
		#p target.instance_methods.sort
		target.extend(ExclusionTarget)
	end
	
	def remove_from(target)
		#instance_methods.each do |meth|
		#	target.send(:undef_method,meth)
		#end
		
		instance_methods.each do |meth|
			backup_meth = "__backup_#{meth}".to_sym
			
			if target.instance_methods.include?(backup_meth)
				target.send(:class_eval) do
					alias_method(meth,backup_meth)
					#undef_method(backup_meth)
					remove_method backup_meth
				end
			else
				target.class_eval do
					define_method(meth) do
						raise 'method has been excluded'
					end
				end
			end
		end
	end
end

module M
	extend ExcludableModule
	
	def mod_meth
		:mod
	end
	
	def conflict_meth
		:mod
	end
end

class A
	
end

class B
	def conflict_meth
		:b
	end
	
	def b
		:b
	end
end

M.inject_into(A)

puts "="*10
p A.instance_methods.include? :mod_meth
p A.instance_methods.include? :conflict_meth

p A.new.mod_meth
p A.new.conflict_meth

puts "="*10

M.inject_into(B)
p B.instance_methods.include? :mod_meth
p B.instance_methods.include? :conflict_meth
p B.instance_methods.include? :__backup_conflict_meth

p B.new.mod_meth
p B.new.conflict_meth

M.remove_from(B)

p B.instance_methods.include? :mod_meth
p B.instance_methods.include? :conflict_meth
p B.instance_methods.include? :b

p B.new.b
p B.new.conflict_meth

#p B.instance_methods

#B.class_eval do
#	alias_method :conflict_meth, :__backup_conflict_meth
#end

