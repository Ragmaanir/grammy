
gem 'rspec'

require 'Grammy'

describe Grammy do

	describe "DEFINITION" do

		it "should define empty grammar" do
			g = Grammy.define :simple do

			end

			g.name.should == :simple
			g.rules.should be_empty
		end

		it "should define grammar with sequence rule via string" do
			g = Grammy.define :simple do
				rule token: 'test'
			end

			g.rules[:token].should be_a Grammar::Sequence
			g.rules[:token].children.should == ['test']
		end

		it "should define grammar with sequence rule via concat" do
			g = Grammy.define :simple do
				rule token: 'test' >> 'other'
			end

			g.rules[:token].should be_a Grammar::Sequence
			g.rules[:token].children.should == ['test','other']
		end

		it "should define grammar with alternative rule via range" do
			g = Grammy.define :simple do
				rule lower: 'a'..'z'
			end

			g.rules[:lower].should be_a Grammar::Alternatives
			g.rules[:lower].children.should == ('a'..'z').to_a
		end

		it "should define grammar with alternative rule via array" do
			g = Grammy.define :simple do
				rule a_or_g: ['a','g']
			end

			g.rules[:a_or_g].should be_a Grammar::Alternatives
			g.rules[:a_or_g].children.should == ['a','g']
		end

		it "should define grammar with alternative rule via symbols" do
			g = Grammy.define :simple do
				rule a: 'a'
				rule b: 'b'
				rule a_or_b: :a | :b
			end

			g.rules[:a_or_b].should be_a Grammar::Alternatives
			g.rules[:a_or_b].children.should == [:a,:b]
		end

		it "should define grammar with repetition via range" do
			g = Grammy.define :simple do
				rule a: 'a'
				rule b: 'b'
				rule as_or_bs: (:a | :b)*(3..77)
			end

			g.rules[:as_or_bs].should be_a Grammar::Repetition
			g.rules[:as_or_bs].repetitions.should == (3..77)
			g.rules[:as_or_bs].children.length.should == 1
			g.rules[:as_or_bs].children.first.should be_a Grammar::Alternatives
		end

		it "should define grammar with repetition via unary plus" do
			g = Grammy.define :simple do
				rule a: 'a'
				rule b: 'b'
				rule as_or_bs: +(:a | :b)
			end

			g.rules[:as_or_bs].should be_a Grammar::Repetition
			g.rules[:as_or_bs].repetitions.should == (1..Grammar::MAX_REPETITION)
			g.rules[:as_or_bs].children.length.should == 1
			g.rules[:as_or_bs].children.first.should be_a Grammar::Alternatives
		end

		it "should define simple grammar" do
			g = Grammy.define :simple do
				rule digits: (0..9) * (0..16)
				rule lower: 'a'..'z'
				rule upper: 'A'..'Z'
				rule letter: :lower | :upper
				rule ident_start: :letter | '_';
				rule ident_letter: :ident_start | ('0'..'9')
				rule ident: :ident_start >> (:ident_letter * (0..128))
				rule method_suffix: ['!','?']
				rule method_id: :ident >> :method_suffix?
			end

			g.rules[:digits].should be_a Grammar::Repetition
			g.rules[:lower].should be_a Grammar::Alternatives
			g.rules[:ident].should be_a Grammar::Sequence
			g.rules[:method_id].should be_a Grammar::Sequence
			g.rules[:method_suffix].should be_a Grammar::Alternatives

			g.rules.each_pair do |name,rule|
				rule.name.should == name
			end
		end

		it "should raise when duplicate rules" do
			expect{
				Grammy.define :simple do
					rule a: 'a'
					rule a: 'b'
				end
			}.to raise_error
		end

	end

	describe "PARSING" do

		describe 'Rule' do

			it "should match character" do
				g = Grammy.define :simple do
					rule lower: 'a'..'z'
				end

				node = g.rules[:lower].match("some",0)
				node.should be_a AST::Node
				node.match_range.should == (0..0)
				node.name.should == :lower
			end

			it "should match one or more characters" do
				g = Grammy.define :simple do
					helper lower: 'a'..'z'
					rule string: +:lower
				end

				node = g.rules[:string].match("some",0)
				node.should be_a AST::Node
				node.match_range.should == (0..3)
				node.name.should == :string
			end

			it "should match string without helper" do
				g = Grammy.define :simple do
					rule lower: 'a'..'z'
					rule string: :lower * (1..16)
				end

				node = g.rules[:string].match("some",0)
				
				node.should be_a AST::Node
				node.name.should == :string
				node.match_range.should == (0..3)
				node.to_s.should_not == "string{'some'}\n"
				node.children.length.should == 4
				node.children.first.to_s.should == "lower{'s'}\n"
			end

			it "should merge helper nodes" do
				g = Grammy.define :simple do
					helper lower: 'a'..'z'
					rule string: :lower * (1..16)
				end

				node = g.rules[:string].match("some",0)
				node.data.should == "some"
				node.children.should be_empty
				node.to_s.should == "string{'some'}\n"
			end
		
		end

		it "should parse string with constant repetition" do
			g = Grammy.define :simple do
				helper lower: 'a'..'z'
				rule string: :lower * 4
			end
			
			tree = g.parse("some",rule: :string)

			tree.data.should == "some"
			tree.to_s.should == "string{'some'}\n"
			tree.children.should be_empty
		end

		it "should parse string with one or more characters" do
			g = Grammy.define :simple do
				helper lower: 'a'..'z'
				rule string: +:lower
			end

			tree = g.parse("somelongerstring",rule: :string)

			tree.data.should == "somelongerstring"
			tree.to_s.should == "string{'somelongerstring'}\n"
			tree.children.should be_empty
		end

		it "should parse string with sequence" do
			g = Grammy.define :simple do
				helper lower: 'a'..'z'
				rule string: :lower >> :lower >> :lower >> :lower
			end

			tree = g.parse("some",rule: :string)
			
			tree.data.should == "some"
			tree.match_range.should == (0..3)
			tree.children.should be_empty
		end

		it "should parse string with constant repetition in sequence" do
			g = Grammy.define :simple do
				helper lower: 'a'..'z'
				rule string: :lower*3 >> :lower
			end

			tree = g.parse("some",rule: :string)
			tree.data.should == "some"
			tree.match_range.should == (0..3)
		end

		it "should parse an identifier" do
			g = Grammy.define :simple do
				helper lower: 'a'..'z'
				helper upper: 'A'..'Z'
				helper letter: :lower | :upper
				helper ident_start: :letter | '_';
				helper ident_letter: :ident_start | ('0'..'9')
				rule ident: :ident_start >> (:ident_letter * (0..128))
			end

			tree = g.parse("some_id0",rule: :ident)
			tree.should be_a AST::Node
			tree.data.should == "some_id0"
		end

		describe "using skipper" do
			
		end

	end

	describe "AST" do
		it "should remove helper nodes" do
			g = Grammy.define :simple do
				helper lower: 'a'..'z'
				helper upper: 'A'..'Z'
				helper letter: :lower | :upper
				helper ident_start: :letter | '_';
				helper ident_letter: :ident_start | ('0'..'9')
				rule ident: :ident_start >> (:ident_letter * (0..128))
			end

			tree = g.parse("some_id0",rule: :ident)

			tree.to_s.should == "ident{'some_id0'}\n"
			tree.children.should be_empty
		end

		it "should only remove helper nodes" do
			g = Grammy.define :simple do
				rule id: ('a'..'z')*(1..10)
				helper part: :id >> ':' >> :id
				rule sent: :part >> '.'
				rule start: :sent*(1..3)
			end

			tree = g.parse("ab:ac.kk:ee.",rule: :start)

			g.rules[:sent].should_not be_helper
			
			tree.data.should == "ab:ac.kk:ee."
			
			tree.children.length.should == 2
			sent1 = tree.children.first
			sent2 = tree.children.last

			sent1.name.should == :sent
			sent2.name.should == :sent
			sent1.data.should == "ab:ac."
			sent2.data.should == "kk:ee."
			
			sent1.children.map{|c| {c.name => c.data}}.should == [{id: 'ab'}, {id: 'ac'}]
			sent2.children.map{|c| {c.name => c.data}}.should == [{id: 'kk'}, {id: 'ee'}]
		end
	end

end
