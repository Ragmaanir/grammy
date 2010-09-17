
require 'spec/spec_helper'

describe Grammy::Rules::RegexRule do

	describe "should define grammar" do
		it "with regex rule" do
			g = Grammy.define do
				rule lower => /[a-z]/
			end

			g.rules[:lower].should be_a Grammar::RegexRule
			g.rules[:lower].children.should be_empty
		end
	end

	describe "should accept" do
		it "with single character regex rule" do
			g = Grammy.define do
				start lower => /[a-z]/
			end
			
			g.should fully_match("a","b","c")
			g.should partially_match("aa","ax")
			g.should not_match("12","1","")
		end

		it "with multiple character regex rule" do
			g = Grammy.define do
				start str => /[a-z]+/
			end

			g.should fully_match("a","g","ag","ax")
			g.should partially_match("abcX","a1")
			g.should not_match("ABC","1abc","1","")
		end
		
		it "with multiple character regex rule and groups" do
			g = Grammy.define do
				start str => /([a-z]+)([0-9])*/
			end

			g.should fully_match("a","g","ag","ax0","g0641")
			g.should partially_match("abcX","a1_")
			g.should not_match("ABC","1abc","1","")
		end
	end

end
