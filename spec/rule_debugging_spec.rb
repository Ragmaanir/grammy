
gem 'rspec'

require 'Grammy'

describe Grammy::Rules::Rule do

	describe "by default should" do

		it "disable debug output for skipper" do
			g = Grammy.define do
				skipper ws: +' '
				start letters: +('a'..'z')
			end

			g.rules[:ws].debug.should == :root_only
			g.rules[:ws].should be_debugging
			g.rules[:ws].children[0].should_not be_debugging
		end


		it "disable debug output for subrules of tokens" do
			g = Grammy.define do
				skipper ws: +' '
				token letter: 'a'..'z'
				start letters: +:letter
			end

			g.rules[:letter].should be_debugging
		end

		it "disable debug output for fragments" do
			g = Grammy.define do
				skipper ws: +' '
				fragment letter: 'a'..'z'
				token word: +:letter
				start sentence: +:word
			end

			g.rules[:letter].should_not be_debugging

			g.parse('wordone   wordtwo')
		end

		it "enable debug output for named rules" do
			g = Grammy.define do
				start letters: +('a'..'z')
			end

			g.rules[:letters].should be_debugging
			g.rules[:letters].children.first.should be_debugging
		end

		it "enable debug output for named rules and their subrules" do
			g = Grammy.define do
				start seq: 'abc' >> ~('a' | 'c')
			end

			g.rules[:seq].should be_debugging
			g.rules[:seq].children[0].should be_debugging

			rep = g.rules[:seq].children[1]
			rep.should be_debugging
			rep.rule.should be_debugging
			rep.rule.children[0].should be_debugging
			rep.rule.children[1].should be_debugging
		end

	end

	it "should be able to enable debug for skipper" do
		g = Grammy.define do
			skipper ws: +' ', debug: :root_only
			start letters: +('a'..'z')
		end

		g.rules[:ws].should be_debugging
	end

#	describe "should output matched data" do
#		it "should" do
#			g = Grammy.define do
#				skipper ws: +' '
#				start letters: +('a'..'z')
#			end
#			
#			g.logger.should_receive(:debug).with()
#			g.parse("a", debug: true)
#		end
#	end

end