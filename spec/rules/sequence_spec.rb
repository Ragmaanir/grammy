
require 'spec/spec_helper'

describe Grammy::Rules::Sequence do

	describe "should" do

		it "define sequence via >>" do
			g = Grammy.define do
				rule token: 'test' >> 'other'
			end

			token_r = g.rules[:token]
			token_r.should be_a Grammar::Sequence
			token_r.should have(2).children
			token_r.children.first.should be_a Grammar::StringRule
			token_r.children.first.string.should == 'test'
			token_r.children.last.should be_a Grammar::StringRule
			token_r.children.last.string.should == 'other'
		end

		it "join long sequences" do
			g = Grammy.define do
				helper a: 'a'
				helper b: 'b'
				rule phrase: :a >> :b >> :a
			end

			phrase = g.rules[:phrase]
			phrase.should be_a Grammar::Sequence

			phrase.should have(3).children
			
			phrase.children.each{|child| child.should be_a Grammar::RuleWrapper}

			phrase.children[0].name.should == :a
			phrase.children[1].name.should == :b
			phrase.children[2].name.should == :a
		end

		it "nest sequences" do
			g = Grammy.define do
				helper a: 'a'
				helper seq: :a >> :a
				rule phrase: :seq >> :seq >> :seq
			end

			phrase = g.rules[:phrase]
			phrase.should be_a Grammar::Sequence
			phrase.should have(3).children

			phrase.children.each {|child|
				child.should be_a Grammar::RuleWrapper
				child.name.should == :seq
			}

			seq = g.rules[:seq]
			seq.should be_a Grammar::Sequence
		end

		it "be using skipper" do
			g = Grammy.define do
				skipper whitespace: ' ' | "\n" | "\t"

				token a: 'ab'
				start start: :a >> :a >> :a
			end

			g.skipper.should be_a Grammar::Alternatives
			g.skipper.type.should == :skipper
			
			g.skipper.should_not be_generating_ast
			g.rules[:a].should_not be_using_skipper
			g.rules[:start].should be_using_skipper
		end

		it "not be backtracking when defined via &-operator" do
			g = Grammy.define do
				helper a: 'ab'
				rule token: :a >> :a & :a >> :a
			end

			token_r = g.rules[:token]
			token_r.should be_a Grammar::Sequence

			token_r.should have(4).children
			token_r.should be_backtracking
			token_r.children[2].should_not be_backtracking
		end

		it "be merging nodes when declared as helper" do
			g = Grammy.define do
				helper a: 'a'
				rule b: 'b'
				rule start: :a >> :b
			end

			start = g.rules[:start]
			
			start.should_not be_merging_nodes
			start.children[0].rule.should be_merging_nodes
			start.children[1].rule.should_not be_merging_nodes
		end

	end

	describe "should accept" do

		it "lower character string" do
			g = Grammy.define do
				helper lower: 'a'..'z'
				start string: :lower >> :lower >> :lower >> :lower
			end
			
			g.should fully_match('abcc','aaaa','cccc','acac','bbbb')
			g.should partially_match('abccc','ccccA')
			g.should not_match('A','Aaaa','1ccc','','aAaa')
		end

		it "with sequence as skipper" do
			g = Grammy.define do
				skipper whitespace: ' ' >> ' '

				token a: 'ab'
				start start: :a >> :a >> :a
			end
			
			g.should fully_match('  ab  ab  ab', 'ab  ab  ab')
			g.should partially_match('ab  ab  ab  ', 'ab  ab  ab  ab', 'ab  ab  abab')
			g.should not_match('  ab    ab  ab', 'ab', '  ab', '  ')

		end

		it "with complex skipper" do
			g = Grammy.define do
				skipper whitespace: +(' ' | "\n" | "\t")

				token a: 'ab'
				start start: :a >> :a >> :a
			end
			
			g.should fully_match("ab   ab   \n\tab", "ab\nab\t  ab")
		end

	end

	describe "should detect errors" do
		it "in sequence when backtracking not allowed" do
			g = Grammy.define do
				helper lower: 'a'..'z'
				start string: :lower >> :lower & :lower >> :lower
			end

			g.parse("").should have(0).errors
			g.parse("x").should have(0).errors
			g.parse("a").should have(0).errors

			g.parse("aa").should have(1).errors
			g.parse("aa1a").should have(1).errors
			g.parse("aaa3").should have(1).errors
		end

		it "in alternative sequences when backtracking not allowed" do
			g = Grammy.define do
				helper a: 'a'
				helper b: 'b'
				start string: (:a & :a) | (:b & :b)
			end

			g.parse("").should have(0).errors
			g.parse("x").should have(0).errors
			g.parse("aa").should have(0).errors
			g.parse("bb").should have(0).errors

			g.parse("a").should have(1).errors
			g.parse("b").should have(1).errors
			g.parse("ab").should have(1).errors
			g.parse("ba").should have(1).errors
		end

		it "in sequence with repetition when backtracking not allowed" do
			g = Grammy.define do
				skipper ws: +(' ' | "\n" | "\t")
				token word: ('a'..'z')*(3..10) #,debug: true
				start string: +:word & eos
			end

			g.parse("abx").should have(0).errors
			g.parse("  abdfc \n").should have(0).errors
			g.parse("asd asd \n ggth").should have(0).errors
			
			g.parse("abc asd \n 3 ").should have(1).errors
			g.parse("abc asd \n asDe ").should have(1).errors
		end

		it "in alternative sequences with words when backtracking not allowed" do
			g = Grammy.define do
				start string: ('aax' & 'bbx') | ('cc' & 'dd')
			end

			g.parse("aaxbbx").should have(0).errors
			g.parse("ccdd").should have(0).errors

			g.parse("aax").should have(1).errors
			g.parse("cc").should have(1).errors
			g.parse("aaxb").should have(1).errors
			g.parse("ccd").should have(1).errors
		end

		it "in nested sequences when backtracking not allowed" do
			g = Grammy.define do
				rule first: 'a' & 'A'
				rule last: 'b' & 'B'
				start lang: :first & :last
			end

			g.parse("aAbB").should have(0).errors
			g.parse("aAB").should have(1).errors
			g.parse("aabB").should have(1).errors
		end

	end # DESC: detect errors

end
