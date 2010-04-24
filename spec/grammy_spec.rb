
gem 'rspec'

require 'Grammy'

describe Grammy do

	describe "should define" do

		it "empty grammar" do
			g = Grammy.define :simple do

			end

			g.name.should == :simple
			g.rules.should be_empty
		end

		it "grammar with list-helper" do
			g = Grammy.define do
				rule item: ('a'..'z')*(2..8)
				start phrase: list(:item)
			end

			phrase = g.rules[:phrase]
			phrase.should be_a Grammar::Sequence
			phrase.should have(2).children
			
			phrase.children[0].should be_a Grammar::RuleWrapper
			phrase.children[0].rule.should == g.rules[:item]

			phrase.children[1].should be_a Grammar::Repetition
			phrase.children[1].repetitions.should == (0..1000)
			phrase.children[1].should have(1).children

			params = phrase.children[1].children[0]
			params.should be_a Grammar::Sequence
			params.should have(2).children
			params.children[0].should be_a Grammar::StringRule
			params.children[1].should be_a Grammar::RuleWrapper
			params.children[1].rule.should == g.rules[:item]
		end

		it "grammar with helper rule" do
			g = Grammy.define do
				helper a: 'a'
				rule b: 'b'
				rule phrase: :a >> :b
			end

			phrase = g.rules[:phrase]
			
			phrase.should be_a Grammar::Sequence
			phrase.should have(2).children
			phrase.children.each{|child| child.should be_a Grammar::RuleWrapper }

			g.rules[:a].should be_helper
			g.rules[:b].should_not be_helper
			
			phrase.children[0].rule.should == g.rules[:a]
			phrase.children[1].rule.should == g.rules[:b]
		end

		it "grammar with duplicate rules and raise" do
			expect{
				Grammy.define do
					rule a: 'a'
					rule a: 'b'
				end
			}.to raise_error
		end

	end

	describe "should parse" do

		it "comma seperated list" do
			g = Grammy.define do
				rule item: ('a'..'z')*(2..8)
				start start: :item >> ~(',' >> :item)
			end

			g.parse("").should be_no_match

			[
				"first",
				"first,second",
				"first,second,third"
			].each { |input|
				g.parse(input).should be_full_match
			}
		end

		it "comma seperated list with list-helper" do
			g = Grammy.define do
				rule item: ('a'..'z')*(2..8)
				start start: list(:item)
			end

			g.parse("").should be_no_match

			[
				"first",
				"first,second",
				"first,second,third"
			].each { |input|
				g.parse(input).should be_full_match
			}
		end

		it "and only skip in rules" do
			g = Grammy.define do
				skipper whitespace: +(' ' | "\n" | "\t")

				token a: 'ab d'
				start start: +:a
			end

			g.parse("ab d\t\n ab d").should be_full_match
		end

	end

end
