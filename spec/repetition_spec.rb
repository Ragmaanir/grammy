
gem 'rspec'

require 'Grammy'

describe Grammy::Rules::Repetition do

	describe "should define grammar" do
		it "with repetition via range" do
			g = Grammy.define do
				rule a: 'a'
				start as: :a*(3..77)
			end

			as = g.rules[:as]
			as.should be_a Grammar::Repetition
			as.repetitions.should == (3..77)
			as.should have(1).children
			as.children.first.name.should == :a
		end

		it "with constant repetition" do
			g = Grammy.define do
				rule a: 'a'
				start const: :a*3
			end

			const = g.rules[:const]
			const.should be_a Grammar::Repetition
			const.repetitions.should == (3..3)
			const.should have(1).children
			const.children.first.name.should == :a
		end

		it "with one or more repetitions for unary +" do
			g = Grammy.define do
				start plus: +'a'
			end

			plus = g.rules[:plus]
			plus.should be_a Grammar::Repetition
			plus.repetitions.should == (1..Grammar::MAX_REPETITIONS)
			plus.should have(1).children
			plus.children.first.should be_a Grammar::StringRule
		end

		it "with zero or more repetitions for unary ~" do
			g = Grammy.define do
				start any: ~'a'
			end

			any = g.rules[:any]
			any.should be_a Grammar::Repetition
			any.repetitions.should == (0..Grammar::MAX_REPETITIONS)
			any.should have(1).children
			any.children.first.should be_a Grammar::StringRule
		end
	end


	describe "should accept" do
		it "string with constant repetition" do
			g = Grammy.define do
				helper lower: 'a'..'z'
				start string: :lower * 4
			end

			['abcc','aaaa','cccc','acac','bbbb'].each { |str|
				g.parse(str).should be_full_match
			}

			['abccd'].each { |str|
				g.parse(str).should be_partial_match
			}

			['',' ',' aaaa','a1aa','ccc'].each { |str|
				g.parse(str).should be_no_match
			}
		end

		it "zero or more characters" do
			g = Grammy.define do
				helper lower: 'a'..'z'
				start string: ~:lower
			end

			g.parse("").should be_full_match
			g.parse("s").should be_full_match
			g.parse("somelongerstring").should be_full_match
			
			g.parse("somelongerstringG").should be_partial_match
			g.parse("A").should be_partial_match
			g.parse(" somelongerstring").should be_partial_match
		end

		it "one or more characters" do
			g = Grammy.define do
				helper lower: 'a'..'z'
				start string: +:lower
			end

			g.parse("a").should be_full_match
			g.parse("somelongerstring").should be_full_match
			
			g.parse("aA").should be_partial_match
			g.parse("asdafasa ").should be_partial_match

			g.parse("").should be_no_match
			g.parse("A").should be_no_match
			g.parse("Aabc").should be_no_match
		end

		it "repetition defined via range" do
			g = Grammy.define do
				rule string: 'abc' | '1234'
				start start: :string * (1..3)
			end

			[
				"1234abc",
				"abcabcabc",
				"12341234",
				"1234"
			].each{ |input|
				g.parse(input).should be_full_match
			}

			[
				"1234ab",
				"1234bc",
				"abc1234abcabc",
				"abcxyzabcabc"
			].each{ |input|
				g.parse(input).should be_partial_match
			}

			[
				"",
				"123abc"
			].each { |input|
				g.parse(input).should be_no_match
			}
		end

	end

end