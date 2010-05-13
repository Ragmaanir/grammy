
require 'spec/spec_helper'

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
			
			g.should fully_match("long_string")
			g.should partially_match("long_stringX")
			g.should not_match("long_strin","Xlong_string")
		end

		it "a string with skipper but should not skip" do
			g = Grammy.define do
				skipper ws: +' '
				start str: 'long_string'
			end
			
			g.should fully_match("long_string")
			g.should partially_match("long_stringX", "long_string ")
			g.should not_match(
				"long_strin",
				"Xlong_string",
				"  long_string",
				" long_stringX",
				"  long_string ",
				"  long_strin",
				" Xlong_string"
			)
		end
	end

end