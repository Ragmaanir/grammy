
gem 'rspec'

require 'Grammy'

describe Grammy::Rules::Sequence do

	describe "DEFINITION" do

		it "should define sequence via >>" do
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

		it "should join long sequences" do
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

		it "should nest sequences" do
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

		it "should have skipper" do
			g = Grammy.define do
				skipper whitespace: ' ' | "\n" | "\t"

				token a: 'ab'
				start start: :a >> :a >> :a
			end

			g.skipper.should be_a Grammar::Alternatives
			g.skipper.should be_helper
			g.skipper.should be_ignored
			g.rules[:a].should_not be_skipping
			g.rules[:start].should be_skipping
		end

		it "should have disabled backtracking" do
			g = Grammy.define do
				helper a: 'ab'
				rule token: :a >> :a & :a >> :a
			end

			token_r = g.rules[:token]
			token_r.should be_a Grammar::Sequence

			#puts token_r
			#p token_r.children
			#token_r.children[2].should_not be_backtracking
			token_r.should have(4).children
			token_r.should be_backtracking
			token_r.children[2].should_not be_backtracking
		end

		it "should have helper rules" do
			g = Grammy.define do
				helper a: 'a'
				rule b: 'b'
				rule start: :a >> :b
			end

			start_r = g.rules[:start]
			
			start_r.should have(2).children

			start_r.children[0].rule.should be_helper
			start_r.children[1].rule.should_not be_helper
		end

	end

	describe "should accept" do

		it "lower character string" do
			g = Grammy.define do
				helper lower: 'a'..'z'
				start string: :lower >> :lower >> :lower >> :lower
			end

			['abcc','aaaa','cccc','acac','bbbb'].each { |str|
				g.parse(str).should be_full_match
			}

			['abccc','ccccA'].each { |str|
				g.parse(str).should be_partial_match
			}

			['A','Aaaa','1ccc','','aAaa'].each { |str|
				g.parse(str).should be_no_match
			}
		end

		it "with sequence as skipper" do
			g = Grammy.define do
				skipper whitespace: ' ' >> ' '

				token a: 'ab'
				start start: :a >> :a >> :a
			end

			g.parse("  ab  ab  ab").should be_full_match
			g.parse("ab  ab  ab").should be_full_match

			g.parse("ab  ab  ab  ").should be_partial_match
			g.parse("ab  ab  ab  ab").should be_partial_match
			g.parse("ab  ab  abab").should be_partial_match

			g.parse("  ab    ab  ab").should be_no_match
			g.parse("ab").should be_no_match
			g.parse("  ab").should be_no_match
			g.parse("  ").should be_no_match
		end

		it "with complex skipper" do
			g = Grammy.define do
				skipper whitespace: +(' ' | "\n" | "\t")

				token a: 'ab'
				start start: :a >> :a >> :a
			end

			g.parse("ab   ab   \n\tab").should be_full_match
			g.parse("ab\nab\t  ab").should be_full_match
		end

	end

	describe "should detect errors" do
		it "in sequence when backtracking not allowed" do
			g = Grammy.define do
				helper lower: 'a'..'z'
				start string: :lower >> :lower & :lower >> :lower
			end

			# TODO move to definition spec
			g.rules[:string].should have(4).children
			g.rules[:string].should be_backtracking
			g.rules[:string].children[2].should_not be_backtracking

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

			# TODO move to definition spec
			g.rules[:string].should have(2).children
			g.rules[:string].children[0].should have(2).children
			g.rules[:string].children[1].should have(2).children
			#g.rules[:string].should_not be_backtracking

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
				helper word: ('a'..'z')*(3..10)
				start string: +:word & eos
			end

			# TODO move to definition spec
			g.rules[:string].should have(2).children

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
			g.parse!("aaxb").should have(1).errors
			g.parse("ccd").should have(1).errors
		end

	end # DESC: detect errors

end
