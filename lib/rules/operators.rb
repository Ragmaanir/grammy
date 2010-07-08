
require 'extensions/removable_module'

module Grammy
	module Rules

		MAX_REPETITIONS = 1_000
		
=begin
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
						#puts "backup #{meth}"
						#target.send(:alias_method,"__backup_#{meth}",meth)
						#target.send(:undef_method,meth)
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
=end

		# Special operators used in the Grammar DSL.
		# The module is designed to be removable so the extra operators
		# wont pollute String, Symbol and Range.
		module Operators
		
			extend ExcludableModule

=begin
			# includes the module so that it can be removed later with #exclude
			def self.included(target)
				# create a clone of the module so the methods can be removed from the
				# clone without affecting the original module
				cloned_mod = self.clone
				my_mod_name = name

				# store the module clone that is included
				target.class_eval {
					@@removable_modules ||= {}
					@@removable_modules[my_mod_name] = cloned_mod
				}

				# make backup of already defined methods
				cloned_mod.instance_methods.each {|imeth|
					if target.instance_methods.include? imeth
						target.send(:alias_method,"__#{imeth}_backup",imeth)
					end
				}

				cloned_mod.send(:append_features,target)
			end

			# removes the module from the target by
			# removing added methods and aliasing the backup
			# methods with their original name
			def self.exclude(target)
				# get the module
				mod = target.send(:class_eval){
					@@removable_modules
				}[name] || raise("module '#{name}' not found in internal hash, cant exclude it")

				# remove / restore the methods
				mod.instance_methods.each {|imeth|
					mod.send(:undef_method,imeth)

					if target.instance_methods.include? "__#{imeth}_backup"
						target.send(:alias_method,imeth,"__#{imeth}_backup")
						target.send(:undef_method,"__#{imeth}_backup")
					end
				}
			end
=end

			def &(right)
				right = Rule.to_rule(right)
				right.backtracking = false
				Sequence.new(nil,[self,right])
			end

			def >>(other)
				Sequence.new(nil,[self,other])
			end

			def |(other)
				Alternatives.new(nil,[self,other])
			end

			def *(times)
				times = times..times if times.is_a? Integer
				raise("times must be a range or int but was: '#{times}'") unless times.is_a? Range

				Repetition.new(nil,Rule.to_rule(self),times: times)
			end

			def +@
				Repetition.new(nil,self,times: 1..MAX_REPETITIONS)
			end

			def ~@
				Repetition.new(nil,self,times: 0..MAX_REPETITIONS)
			end
		end

	end

end
