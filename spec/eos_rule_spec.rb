
gem 'rspec'

require 'Grammy'

describe Grammy::Rules::EOSRule do

	it "should only match end of stream" do
		g = Grammy.define :eos do
			start phrase: 'first' >> 'last' >> eos
		end

		g.rules[:phrase].should have(3).children
		g.rules[:phrase].children[2].should be_a Grammar::EOSRule

		eos = g.rules[:phrase].children[2]
		eos.match("",0).should be_success
		eos.match("a",0).should be_failure
		eos.match("\n",0).should be_failure
		eos.match(" ",0).should be_failure
	end

	describe "should accept" do

		it "end of stream" do
			g = Grammy.define :eos do
				start phrase: 'first' >> 'last' >> eos
			end

			g.parse("firstlast").should be_full_match
			g.parse("firstlast ").should be_no_match
			g.parse("firstlastx").should be_no_match
		end

		it "end of stream with skipper" do
			g = Grammy.define :eos do
				skipper ws: +' '
				start phrase: 'first' >> 'last' >> eos
			end

			g.parse("firstlast").should be_full_match
			g.parse("first   last  ").should be_full_match
			g.parse("first last x").should be_no_match
		end

	end

end