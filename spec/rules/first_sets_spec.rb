
require 'spec/spec_helper'

describe Grammy::Rules::Rule do

	describe "should calculate first set for" do
		it "string rule" do
			g = Grammy.define do
				rule a => 'a'
			end

			g.rules[:a].first_set.should == ['a'].to_set
		end
		
		it "alternative" do
			g = Grammy.define do
				rule alt => 'a' | 'b' | 'c'
			end

			g.rules[:alt].first_set.should == ['a','b','c'].to_set
		end
		
		it "rule wrapper" do
			g = Grammy.define do
				rule a => 'a'
				rule ref => a
			end

			g.rules[:ref].first_set.should == g.rules[:a].first_set
		end
		
		it "optional rule wrapper" do
			g = Grammy.define do
				rule a => 'a'
				rule ref => a?
			end

			g.rules[:ref].first_set.should == g.rules[:a].first_set + [nil]
		end
		
		it "repitition: at least one" do
			g = Grammy.define do
				rule a => 'a'
				rule rep => +a
			end

			g.rules[:rep].first_set.should == g.rules[:a].first_set
		end
		
		it "repitition of optinal rules: at least one" do
			g = Grammy.define do
				rule a => 'a'
				rule rep => +(a?)
			end

			g.rules[:rep].first_set.should == g.rules[:a].first_set + [nil]
		end
		
		it "repitition: zero or more" do
			g = Grammy.define do
				rule a => 'a'
				rule rep => ~a
			end

			g.rules[:rep].first_set.should == g.rules[:a].first_set + [nil]
		end
		
		it "sequence" do
			g = Grammy.define do
				rule seq => 'a' >> 'b'
			end

			g.rules[:seq].first_set.should == ['a'].to_set
		end
		
		it "sequence with optional rule" do
			g = Grammy.define do
				rule a => 'a'
				rule seq => a? >> 'b'
			end

			g.rules[:seq].first_set.should == ['a','b'].to_set
		end
		
		it "sequence with only optional rules" do
			g = Grammy.define do
				rule a => 'a'
				rule b => 'b'
				rule seq => a? >> b?
			end

			g.rules[:seq].first_set.should == ['a','b',nil].to_set
		end
		
		it "sequence with alternative" do
			g = Grammy.define do
				rule a => 'a' | 'b' | 'c'
				rule seq => a? >> 'x'
			end

			g.rules[:seq].first_set.should == ['a','b','c','x'].to_set
		end
	end

end
