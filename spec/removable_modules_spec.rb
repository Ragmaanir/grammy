
gem 'rspec'
require 'Grammy'

describe "RemovableModules" do

	it "should add module" do
		C = Class.new do
			include Grammy::Rules::Operators
		end

		C.instance_methods.should include(:+@)
		C.instance_methods.should include(:'>>')
		C.instance_methods.should include(:'*')
	end

	it "should add and remove module" do
		C = Class.new do
			include Grammy::Rules::Operators
		end

		Grammy::Rules::Operators.exclude(C)

		C.instance_methods.should_not include(:+@)
		C.instance_methods.should_not include(:'>>')
		C.instance_methods.should_not include(:'*')
	end

	it "should restore old methods"

end