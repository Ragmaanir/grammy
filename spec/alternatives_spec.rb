
gem 'rspec'

require 'Grammy'

describe Grammy::Rules::Alternatives do

	describe "should define grammar" do
		it "with alternatives via '|' operator" do
			g = Grammy.define do
				rule lower: 'a' | 'b' | 'c'
			end

			g.rules[:lower].should be_a Grammar::Alternatives
			g.rules[:lower].should have(3).children
			g.rules[:lower].children.each{ |child| child.should be_a Grammar::StringRule }
		end

		it "with alternative rule via array" do
			g = Grammy.define do
				rule a_or_g: ['a','g']
			end

			a_or_g = g.rules[:a_or_g]
			a_or_g.should be_a Grammar::Alternatives
			a_or_g.should have(2).children
			a_or_g.children[0].should be_a Grammar::StringRule
			a_or_g.children[1].should be_a Grammar::StringRule
		end

		it "with alternative rule via symbols" do
			g = Grammy.define do
				rule a: 'a'
				rule b: 'b'
				rule a_or_b: :a | :b
			end

			g.rules[:a_or_b].should be_a Grammar::Alternatives
			g.rules[:a_or_b].should have(2).children
			g.rules[:a_or_b].children[0].should be_a Grammar::RuleWrapper
			g.rules[:a_or_b].children[1].should be_a Grammar::RuleWrapper
		end
	end

	describe "should accept" do
		it "with alternatives via '|' operator" do
			g = Grammy.define do
				start lower: 'a' | 'b' | 'c'
			end

			g.parse("a").should be_full_match
			g.parse("b").should be_full_match
			g.parse("c").should be_full_match

			g.parse("aa").should be_partial_match
			g.parse("ax").should be_partial_match

			g.parse("xd").should be_no_match
			g.parse("d").should be_no_match
			g.parse("").should be_no_match
		end

		it "with alternative rule via array" do
			g = Grammy.define do
				start a_or_g: ['a','g']
			end

			g.parse("a").should be_full_match
			g.parse("g").should be_full_match

			g.parse("ag").should be_partial_match
			g.parse("ax").should be_partial_match

			g.parse("xd").should be_no_match
			g.parse("d").should be_no_match
			g.parse("").should be_no_match
		end
	end

end