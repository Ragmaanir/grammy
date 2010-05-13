module Grammy
	module Rules

		MAX_REPETITIONS = 10_000

		# Special operators used in the Grammar DSL.
		# The module is designed to be removable so the extra operators
		# wont pollute String, Symbol and Range.
		module Operators

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