
require 'spec/spec_helper'

describe Grammy::Rules::RangeRule do

	describe "should define" do
		it "range from a to z" do
			g = Grammy.define do
				start lower: 'a'..'z'
			end

			g.rules[:lower].should have_properties(
				:range => 'a'..'z',
				:class => Grammar::RangeRule
			)
		end

		it "range from 1 to 9" do
			g = Grammy.define do
				start digit: '1'..'9'
			end

			g.rules[:digit].should have_properties(
				:range => '1'..'9',
				:class => Grammar::RangeRule
			)
		end
	end

	describe "should accept" do
		it "letters" do
			g = Grammy.define do
				start lower: 'a'..'z'
			end

			g.should fully_match("a")
			g.should partially_match("ab")
			g.should not_match("","A")
		end

		it "digits" do
			g = Grammy.define do
				start lower: '0'..'9'
			end

			g.should fully_match('1')
			g.should partially_match('11')
			g.should not_match('','A')
		end

		it "letters with skipper" do
			g = Grammy.define do
				default_skipper ws: +' '
				start lower: 'a'..'z'
			end

			g.should fully_match('  a')
			g.should partially_match('ab',' a  ')
			g.should not_match('','A')
		end
	end

end