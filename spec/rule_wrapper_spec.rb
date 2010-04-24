
gem 'rspec'

require 'Grammy'

describe Grammy::Rules::RuleWrapper do

	describe "should define" do
		it "non-optional rule" do
			g = Grammy.define do
				rule a: 'a'
				start char: :a
			end

			char = g.rules[:char]

			char.should be_a Grammar::RuleWrapper
			char.name.should == :a
			char.rule.should == g.rules[:a]
			char.should_not be_optional

			char.match("a",0).should be_success
			char.match("aa",0).should be_success
			char.match("",0).should be_failure
			char.match("b",0).should be_failure
		end

		it "optional rule" do
			g = Grammy.define do
				rule a: 'a'
				start char: :a?
			end

			char = g.rules[:char]

			char.should be_a Grammar::RuleWrapper
			char.name.should == :a
			char.rule.should == g.rules[:a]
			char.should be_optional

			char.match("",0).should be_success
			char.match("a",0).should be_success
			char.match("aa",0).should be_success
			char.match("b",0).should be_success
		end
	end

	describe "should accept" do
		it "string with optional rule" do
			g = Grammy.define do
				rule a: 'a'
				start char: :a?
			end

			g.parse('').should be_full_match
			g.parse('a').should be_full_match
			g.parse('ac').should be_partial_match
			g.parse('b').should be_partial_match
			g.parse('ba').should be_partial_match
		end

		it "sequence of optional rules" do
			g = Grammy.define do
				rule a: 'a'
				start char: :a? >> :a? >> 'b'
			end

			g.parse('aab').should be_full_match
			g.parse('ab').should be_full_match
			g.parse('b').should be_full_match
			g.parse('').should be_no_match
			g.parse('aa').should be_no_match
			g.parse('a').should be_no_match
		end
	end

	describe "should" do
		it "not generate ast-node when optional rule skipped" do
			g = Grammy.define do
				rule a: 'a'
				start char: '<' >> :a? >> '>'
			end

			g.parse("<>").tree.should have(0).children
		end

		it "generate ast-node when optional rule not skipped" do
			g = Grammy.define do
				rule a: 'a'
				start char: '<' >> :a? >> '>'
			end

			g.parse("<a>").tree.should have(1).children
		end
	end

end