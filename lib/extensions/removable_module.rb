
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
					define_method(meth) do |*args|
						super(*args)
					end
				end
			end
		end
		
		append_features(target)
		target.extend(ExclusionTarget)
	end
	
	def remove_from(target)
		instance_methods.each do |meth|
			backup_meth = "__backup_#{meth}".to_sym
			if target.instance_methods.include?(backup_meth)
				target.send(:class_eval) do
					alias_method(meth,backup_meth)
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

