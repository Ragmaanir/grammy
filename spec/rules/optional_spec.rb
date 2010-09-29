
require 'spec/spec_helper'

describe Grammy::Rules::OptionalRule do
	
	describe "should define" do
	
		it "optional rule via ?" do
			g = Grammy.define do
				rule a => 'a'
				start char => a?
			end

			#g.rules[:char].should have_properties(
			#	:name => :char,
			#	:class => Grammar::OptionalRule
			#)
			
			char = g.rules[:char]
			char.should be_a(Grammar::OptionalRule)
			char.rule.should be_a(Grammar::RuleReference)
			char.rule.referenced_rule.should == g.rules[:a]
		end
		
		it "optional rule via [...]" do
			g = Grammy.define do
				start char => ['a']
			end

			g.rules[:char].should have_properties(
				:name => :char,
				:class => Grammar::OptionalRule
			)
			g.rules[:char].rule.should be_a(Grammar::StringRule)
		end
		
		it "optional rule sequence via [...]" do
			g = Grammy.define do
				start char => ['a' >> 'b']
			end

			g.rules[:char].should have_properties(
				:name => :char,
				:class => Grammar::OptionalRule
			)
			g.rules[:char].rule.should be_a(Grammar::Sequence)
			g.rules[:char].rule.should have(2).children
		end
		
		it "nested optional rule" do
			g = Grammy.define do
				start char => [['a' >> 'b']]
			end

			g.rules[:char].should be_a(Grammar::OptionalRule)
			g.rules[:char].rule.should be_a(Grammar::OptionalRule)
			g.rules[:char].rule.rule.should be_a(Grammar::Sequence)
			g.rules[:char].rule.rule.should have(2).children
		end
		
		it "optional rule and raise when array has more than one entry" do
			expect{
				g = Grammy.define do
					start char => ['a','b']
				end
			}.to raise_error
		end
		
	end

	describe "should accept" do
		it "string with optional rule defined with ?" do
			g = Grammy.define do
				rule a => 'a'
				start char => a?
			end
			
			g.should fully_match('','a')
			g.should partially_match('ac','b','ba')
		end
		
		it "string with optional rule defined with [..]" do
			g = Grammy.define do
				start char => ['a']
			end
			
			g.should fully_match('','a')
			g.should partially_match('ac','b','ba')
		end

		it "sequence of optional rules" do
			g = Grammy.define do
				rule a => 'a'
				start char => a? >> [a] >> 'b'
			end
			
			g.should fully_match('aab','ab','b')
			g.should partially_match('aaba','ab ','ba')
			g.should not_match('','aa','a')
		end
		
		it "optional sequence" do
			g = Grammy.define do
				rule a => 'a'
				start char => '[' >> [a >> 'b' >> [a]] >> ']'
			end
			
			g.should fully_match('[]','[ab]','[aba]')
			g.should partially_match('[ab]c','[aba] ','[aba]]a')
			g.should not_match('','[aa]','[abaa]')
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
		
		it "generate ast-node when optional rule defnied via [] not skipped" do
			g = Grammy.define do
				rule a => 'a'
				start char => '<' >> [a] >> '>'
			end

			g.parse("<a>").tree.should have(1).children
		end
	end
	
end
