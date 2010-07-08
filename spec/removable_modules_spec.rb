
require 'spec/spec_helper'

describe "RemovableModules" do

	before do
		@m = Module.new do
			extend ExcludableModule
			def mod_meth
				:of_module
			end
		end
		
		@c = Class.new do
			def mod_meth
				:of_class
			end
			
			def cls_meth
				:of_class
			end
		end
	end

	it "should include methods" do
		@m.inject_into(@c)
		
		@c.instance_methods.should include(:mod_meth)
		@c.new.mod_meth.should == :of_module
	end
	
	it "should add exclude-method to target" do
		@m.inject_into(@c)
		@c.methods.should include(:exclude)
	end
	
	it "should backup existing methods" do
		@m.inject_into(@c)
		@c.instance_methods.should include(:__backup_mod_meth)
	end

	it "should restore old methods" do
		@m.inject_into(@c)
		
		@c.new.mod_meth.should == :of_module
		
		@m.remove_from(@c)
		
		@c.new.mod_meth.should == :of_class
	end

end
