
require 'spec/spec_helper'

describe Grammy::Rules::EOSRule do

	it "should define grammar with eos rule" do
		g = Grammy.define do
			start phrase => 'first' >> 'last' >> eos
		end

		g.rules[:phrase].should have(3).children
		g.rules[:phrase].children[2].should be_a Grammar::EOSRule
	end

	describe "should accept" do

		it "only end of stream" do
			g = Grammy.define do
				start phrase => eos
			end

			g.should fully_match('')
			g.should not_match(' ','a')
		end

		it "end of stream" do
			g = Grammy.define do
				start phrase => 'first' >> 'last' >> eos
			end
			
			g.should fully_match("firstlast")
			g.should not_match("firstlast ","firstlastx")
		end

		it "only end of stream with skipper" do
			g = Grammy.define do
				default_skipper ws => +' '
				start phrase => eos
			end
			
			g.should fully_match(""," ","     ")
			g.should not_match(" a ")
		end

		it "end of stream with skipper" do
			g = Grammy.define do
				default_skipper ws => +' '
				start phrase => 'first' >> 'last' >> eos
			end
			
			g.should fully_match("firstlast","first   last  ")
			g.should not_match("first last x")
		end

	end

end
