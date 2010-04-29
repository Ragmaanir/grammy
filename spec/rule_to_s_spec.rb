
gem 'rspec'

require 'Grammy'

describe Grammy::Rules::Rule do
	
	describe "to_s should" do
		it "return sequence of rules as string" do
			g = Grammy.define do
				token a: 'ab'
				token b: 'asd'
				start start: :a >> :b >> :a
			end

			g.rules[:start].to_s.should == ":a >> :b >> :a"
		end

		it "return sequence with optional rules as string" do
			g = Grammy.define do
				token a: 'ab'
				token b: 'asd'
				start start: :a >> :b? >> :a?
			end

			g.rules[:start].to_s.should == ":a >> :b? >> :a?"
		end

		it "return sequence of strings as string" do
			g = Grammy.define do
				start start: 'a' >> 'y' >> 'z'
			end

			g.rules[:start].to_s.should == "'a' >> 'y' >> 'z'"
		end

		it "return sequence with an alternative as string" do
			g = Grammy.define do
				start start: 'a' >> ('b' | 'cde')
			end

			g.rules[:start].to_s.should == "'a' >> ('b' | 'cde')"
		end

		it "return sequence with repetition as string" do
			g = Grammy.define do
				start start: 'a' >> ~'xyz' >> 'c'
			end

			g.rules[:start].to_s.should == "'a' >> ~'xyz' >> 'c'"
		end

		it "return sequence with repetition of subrule as string" do
			g = Grammy.define do
				start start: 'a' >> ~('xy' >> 'z') >> 'c'
			end

			g.rules[:start].to_s.should == "'a' >> ~('xy' >> 'z') >> 'c'"
		end
	end

end
