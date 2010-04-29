
gem 'rspec'

require 'Grammy'

describe Grammy::Rules::StringRule do

	describe "should define grammar" do
		it "with string rule" do
			g = Grammy.define do
				start str: 'long_string'
			end

			g.rules[:str].should be_a Grammar::StringRule
			g.rules[:str].should have(0).children
		end
	end

	describe "should accept" do
		it "a string" do
			g = Grammy.define do
				start str: 'long_string'
			end

			g.parse("long_string").should be_full_match
			
			g.parse("long_stringX").should be_partial_match

			g.parse("long_strin").should be_no_match
			g.parse("Xlong_string").should be_no_match
		end

		it "a string with skipper but should not skip" do
			g = Grammy.define do
				skipper ws: +' '
				start str: 'long_string'
			end

#			g.parse("  long_string").should be_full_match
#
#			g.parse(" long_stringX").should be_partial_match
#			g.parse("long_string ").should be_partial_match
#
#			g.parse("  long_strin").should be_no_match
#			g.parse(" Xlong_string").should be_no_match

			g.parse("long_string").should be_full_match

			g.parse("long_stringX").should be_partial_match
			g.parse("long_string ").should be_partial_match

			g.parse("long_strin").should be_no_match
			g.parse("Xlong_string").should be_no_match

			g.parse("  long_string").should be_no_match

			g.parse(" long_stringX").should be_no_match
			g.parse("  long_string ").should be_no_match

			g.parse("  long_strin").should be_no_match
			g.parse(" Xlong_string").should be_no_match
		end
	end

end