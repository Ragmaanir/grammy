
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

			g.rules[:string].should have(4).children
			g.rules[:string].should be_backtracking
			g.rules[:string].children[2].should_not be_backtracking

			expect{ g.parse("") }.to_not raise_exception(Grammy::ParseError)
			expect{ g.parse("x") }.to_not raise_exception(Grammy::ParseError)
			expect{ g.parse("a") }.to_not raise_exception(Grammy::ParseError)

			expect{ g.parse("aa") }.to raise_exception(Grammy::ParseError)
			expect{ g.parse("aa1a") }.to raise_exception(Grammy::ParseError)
			expect{ g.parse("aaa3") }.to raise_exception(Grammy::ParseError)
		end

		it "in alternative sequences when backtracking not allowed" do
			g = Grammy.define do
				helper a: 'a'
				helper b: 'b'
				start string: (:a & :a) | (:b & :b)
			end

			g.rules[:string].should have(2).children
			g.rules[:string].children[0].should have(2).children
			g.rules[:string].children[1].should have(2).children
			#g.rules[:string].should_not be_backtracking

			expect{ g.parse("") }.to_not raise_exception(Grammy::ParseError)
			expect{ g.parse("x") }.to_not raise_exception(Grammy::ParseError)
			expect{ g.parse("aa") }.to_not raise_exception(Grammy::ParseError)
			expect{ g.parse("bb") }.to_not raise_exception(Grammy::ParseError)

			expect{ g.parse("a") }.to raise_exception(Grammy::ParseError)
			expect{ g.parse("b") }.to raise_exception(Grammy::ParseError)
			expect{ g.parse("ab") }.to raise_exception(Grammy::ParseError)
			expect{ g.parse("ba") }.to raise_exception(Grammy::ParseError)
		end

		it "in alternative sequences when backtracking not allowed" do
			g = Grammy.define do
				skipper ws: +(' ' | "\n" | "\t")
				helper word: ('a'..'z')*(3..10)
				start string: +:word & eos
			end

			g.rules[:string].should have(2).children

			expect{ g.parse("abx") }.to_not raise_exception(Grammy::ParseError)
			expect{ g.parse("  abdfc \n") }.to_not raise_exception(Grammy::ParseError)
			expect{ g.parse("asd asd \n ggth") }.to_not raise_exception(Grammy::ParseError)
			
			begin
				g.parse("abc asd \n 3 ", debug: true)
			rescue Grammy::ParseError => e
				e.line_number.should == 2
				e.message.should == "Syntax error in line 2 at X: expected :word"
			end
		end
	end

	describe "should" do
		it "return sequence of rules as string with to_s" do
			g = Grammy.define do
				token a: 'ab'
				token b: 'asd'
				start start: :a >> :b >> :a
			end

			g.rules[:start].to_s.should == ":a >> :b >> :a"
		end

		it "return sequence with optional rules as string with to_s" do
			g = Grammy.define do
				token a: 'ab'
				token b: 'asd'
				start start: :a >> :b? >> :a?
			end

			g.rules[:start].to_s.should == ":a >> :b? >> :a?"
		end

		it "return sequence of strings as string with to_s" do
			g = Grammy.define do
				start start: 'a' >> 'y' >> 'z'
			end

			g.rules[:start].to_s.should == "'a' >> 'y' >> 'z'"
		end
		
		it "return sequence with an alternative as string with to_s" do
			g = Grammy.define do
				start start: 'a' >> ('b' | 'cde')
			end

			g.rules[:start].to_s.should == "'a' >> ('b' | 'cde')"
		end

		it "return sequence with repetition as string with to_s" do
			g = Grammy.define do
				start start: 'a' >> ~'xyz' >> 'c'
			end

			g.rules[:start].to_s.should == "'a' >> ~'xyz' >> 'c'"
		end

		it "return sequence with repetition of subrule as string with to_s" do
			g = Grammy.define do
				start start: 'a' >> ~('xy' >> 'z') >> 'c'
			end

			g.rules[:start].to_s.should == "'a' >> ~('xy' >> 'z') >> 'c'"
		end
	end

end
