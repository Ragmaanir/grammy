
gem 'rspec'

require 'Grammy'

describe Grammy::Rules::StringRule do

	describe "should define grammar" do
		it "with string rule" do
			g = Grammy.define :string do
				start str: 'long_string'
			end

			g.rules[:str].should be_a Grammar::StringRule
			g.rules[:str].should have(0).children
		end
	end

	describe "should match exactly" do
		it "a string" do
			g = Grammy.define :string do
				start str: 'long_string'
			end

			g.rules[:str].match("long_string",0).should be_success
			g.rules[:str].match("long_stringx",0).should be_success

			g.rules[:str].match("longer_string",0).should be_failure
			g.rules[:str].match("_long_string",0).should be_failure
		end
	end

	describe "should accept" do
		it "a string" do
			g = Grammy.define :string do
				start str: 'long_string'
			end

			g.parse("long_string").should be_full_match
			
			g.parse("long_stringer").should be_partial_match

			g.parse("long_strin").should be_no_match
			g.parse("along_string").should be_no_match
		end
	end

end