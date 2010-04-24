
gem 'rspec'

require 'Grammy'

describe Grammy::Rules::RangeRule do

	describe "sould define" do
		it "range from a to z" do
			g = Grammy.define do
				start lower: 'a'..'z'
			end

			g.rules[:lower].should be_a Grammar::RangeRule
			g.rules[:lower].range.should == ('a'..'z')
			g.rules[:lower].match("a",0).should be_success
			g.rules[:lower].match("A",0).should be_failure
		end

		it "range from 1 to 9" do
			g = Grammy.define do
				start digit: '1'..'9'
			end

			g.rules[:digit].should be_a Grammar::RangeRule
			g.rules[:digit].range.should == ('1'..'9')
			g.rules[:digit].match("1",0).should be_success
			g.rules[:digit].match("A",0).should be_failure
		end
	end

	describe "should accept" do
		it "letters" do
			g = Grammy.define do
				start lower: 'a'..'z'
			end

			g.parse("a").should be_full_match
			g.parse("ab").should be_partial_match
			g.parse("").should be_no_match
			g.parse("A").should be_no_match
		end

		it "digits" do
			g = Grammy.define do
				start lower: '0'..'9'
			end

			g.parse("1").should be_full_match
			g.parse("11").should be_partial_match
			g.parse("").should be_no_match
			g.parse("A").should be_no_match
		end
	end

end