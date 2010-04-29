
gem 'rspec'

require 'Grammy'

describe Grammy::Rules::EOSRule do

	it "should define grammar with eos rule" do
		g = Grammy.define do
			start phrase: 'first' >> 'last' >> eos
		end

		g.rules[:phrase].should have(3).children
		g.rules[:phrase].children[2].should be_a Grammar::EOSRule
	end

	describe "should accept" do

		it "only end of stream" do
			g = Grammy.define do
				start phrase: eos
			end

			g.parse("").should be_full_match
			g.parse(" ").should be_no_match
		end

		it "end of stream" do
			g = Grammy.define do
				start phrase: 'first' >> 'last' >> eos
			end

			g.parse("firstlast").should be_full_match
			g.parse("firstlast ").should be_no_match
			g.parse("firstlastx").should be_no_match
		end

		it "only end of stream with skipper" do
			g = Grammy.define do
				skipper ws: +' '
				start phrase: eos
			end

			g.parse("").should be_full_match
			g.parse(" ").should be_full_match
			g.parse("     ").should be_full_match
			g.parse(" a ").should be_no_match
		end

		it "end of stream with skipper" do
			g = Grammy.define do
				skipper ws: +' '
				start phrase: 'first' >> 'last' >> eos
			end

			g.parse("firstlast").should be_full_match
			g.parse("first   last  ").should be_full_match
			g.parse("first last x").should be_no_match
		end

	end

end