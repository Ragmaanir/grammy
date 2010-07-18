
require 'spec/spec_helper'

describe Grammy::Rules::RuleWrapper do

	describe "should define" do
		it "non-optional rule" do
			g = Grammy.define do
				rule a => 'a'
				start char => a
			end

			g.rules[:char].should have_properties(
				:name => :char,
				:class => Grammar::RuleWrapper,
				:rule => g.rules[:a],
				:optional? => false
			)
		end

		it "optional rule" do
			g = Grammy.define do
				rule a => 'a'
				start char => a?
			end

			g.rules[:char].should have_properties(
				:name => :char,
				:class => Grammar::RuleWrapper,
				:rule => g.rules[:a],
				:optional? => true
			)
		end
	end

	describe "should accept" do
		it "string with optional rule" do
			g = Grammy.define do
				rule a => 'a'
				start char => a?
			end
			
			g.should fully_match('','a')
			g.should partially_match('ac','b','ba')
		end

		it "sequence of optional rules" do
			g = Grammy.define do
				rule a => 'a'
				start char => a? >> a? >> 'b'
			end
			
			g.should fully_match('aab','ab','b')
			g.should partially_match('aaba','ab ','ba')
			g.should not_match('','aa','a')
		end
	end

	describe "should" do
		it "not generate ast-node when optional rule skipped" do
			g = Grammy.define do
				rule a => 'a'
				start char => '<' >> a? >> '>'
			end

			g.parse("<>").tree.should have(0).children
		end

		it "not generate ast-node with wrapper rules when optional rule skipped" do
			g = Grammy.define do
				rule a => 'a' >> 'b'
				rule x => 'x'
				start char => x >> a? >> x
			end

			g.parse("xx").tree.should have(2).children
		end

		it "generate ast-node when optional rule not skipped" do
			g = Grammy.define do
				rule a => 'a'
				start char => '<' >> a? >> '>'
			end

			g.parse("<a>").tree.should have(1).children
		end
	end

end
