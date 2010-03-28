
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

			token_r = g.rules[:token]
			token_r.should be_a Grammar::StringRule
			token_r.children.should be_empty
			token_r.string.should == "test"
		end

		it "should define grammar with sequence rule via concat" do
			g = Grammy.define :simple do
				rule token: 'test' >> 'other'
			end

			token_r = g.rules[:token]
			token_r.should be_a Grammar::Sequence
			token_r.children.length.should == 2
			token_r.children.first.should be_a Grammar::StringRule
			token_r.children.first.string.should == 'test'
			token_r.children.last.should be_a Grammar::StringRule
			token_r.children.last.string.should == 'other'
		end

		it "should define grammar with long sequence rule via concat" do
			g = Grammy.define :simple do
				helper a: 'a'
				helper b: 'b'
				rule token: :a >> :b >> :a
			end

			token_r = g.rules[:token]
			token_r.should be_a Grammar::Sequence
			
			token_r.children.length.should == 3
			token_r.children[0].should be_a Grammar::RuleWrapper
			token_r.children[0].rule.string.should == 'a'
			token_r.children[1].should be_a Grammar::RuleWrapper
			token_r.children[1].rule.string.should == 'b'
			token_r.children[2].should be_a Grammar::RuleWrapper
			token_r.children[2].rule.string.should == 'a'
		end

		it "should define grammar with long sequence of same rule via concat" do
			g = Grammy.define :simple do
				helper a: 'ab'
				rule token: :a >> :a >> :a
			end

			token_r = g.rules[:token]
			token_r.should be_a Grammar::Sequence
			
			token_r.children.length.should == 3
			token_r.children[0].should be_a Grammar::RuleWrapper
			token_r.children[0].rule.string.should == 'ab'
			token_r.children[1].should be_a Grammar::RuleWrapper
			token_r.children[1].rule.string.should == 'ab'
			token_r.children[2].should be_a Grammar::RuleWrapper
			token_r.children[2].rule.string.should == 'ab'
		end

		it "should define grammar with alternative rule via range" do
			g = Grammy.define :simple do
				rule lower: 'a'..'z'
			end

			g.rules[:lower].should be_a Grammar::RangeRule
			g.rules[:lower].range.should == ('a'..'z')
		end

		it "should define grammar with alternative rule via array" do
			g = Grammy.define :simple do
				rule a_or_g: ['a','g']
			end

			a_or_g = g.rules[:a_or_g]
			a_or_g.should be_a Grammar::Alternatives
			a_or_g.children.length.should == 2
			a_or_g.children[0].should be_a Grammar::StringRule
			a_or_g.children[1].should be_a Grammar::StringRule
		end

		it "should define grammar with alternative rule via symbols" do
			g = Grammy.define :simple do
				rule a: 'a'
				rule b: 'b'
				rule a_or_b: :a | :b
			end

			g.rules[:a_or_b].should be_a Grammar::Alternatives
			#g.rules[:a_or_b].children.should == [:a,:b]
			g.rules[:a_or_b].children.length.should == 2
			g.rules[:a_or_b].children[0].should be_a Grammar::RuleWrapper
			g.rules[:a_or_b].children[1].should be_a Grammar::RuleWrapper
		end

		it "should define grammar with repetition via range" do
			g = Grammy.define :simple do
				rule a: 'a'
				rule b: 'b'
				rule as_or_bs: (:a | :b)*(3..77)
			end

			as_or_bs_r = g.rules[:as_or_bs]
			as_or_bs_r.should be_a Grammar::Repetition
			as_or_bs_r.repetitions.should == (3..77)
			as_or_bs_r.children.length.should == 1
			as_or_bs_r.children.first.should be_a Grammar::Alternatives
		end

		it "should define grammar with repetition via unary plus" do
			g = Grammy.define :simple do
				rule a: 'a'
				rule b: 'b'
				rule as_or_bs: +(:a | :b)
			end

			as_or_bs_r = g.rules[:as_or_bs]
			as_or_bs_r.should be_a Grammar::Repetition
			as_or_bs_r.repetitions.should == (1..Grammar::MAX_REPETITION)
			as_or_bs_r.children.length.should == 1
			as_or_bs_r.children.first.should be_a Grammar::Alternatives
		end

		it "should define grammar with optional rule" do
			g = Grammy.define :simple do
				rule a: 'a'
				rule b: 'b'
				rule start: :a? >> :b
			end

			start_r = g.rules[:start]
			start_r.should be_a Grammar::Sequence
			start_r.children.length.should == 2
			start_r.children.first.should be_a Grammar::RuleWrapper
			start_r.children.first.should be_optional
		end

		it "should define grammar with helper rule" do
			g = Grammy.define :simple do
				helper a: 'a'
				rule b: 'b'
				rule start: :a >> :b
			end

			start_r = g.rules[:start]
			start_r.should be_a Grammar::Sequence
			start_r.name.should == :start
			start_r.children.length.should == 2
			start_r.children[0].should be_a Grammar::RuleWrapper
			start_r.children[0].name.should == :a
			start_r.children[0].rule.should be_helper
			start_r.children[1].should be_a Grammar::RuleWrapper
			start_r.children[1].name.should == :b
			start_r.children[1].rule.should_not be_helper
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
			g.rules[:lower].should be_a Grammar::RangeRule
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

				node = g.rules[:lower].match("some",0).ast_node
				node.should be_a AST::Node
				node.match_range.should == (0..0)
				node.name.should == :lower
			end

			it "should match one or more characters" do
				g = Grammy.define :simple do
					helper lower: 'a'..'z'
					rule string: +:lower
				end

				node = g.rules[:string].match("some",0).ast_node
				node.should be_a AST::Node
				node.match_range.should == (0..3)
				node.name.should == :string
			end

			it "should match string without helper" do
				g = Grammy.define :simple do
					rule lower: 'a'..'z'
					rule string: :lower * (1..16)
				end

				node = g.rules[:string].match("some",0).ast_node
				
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

				node = g.rules[:string].match("some",0).ast_node
				node.data.should == "some"
				node.children.should be_empty
				node.to_s.should == "string{'some'}\n"
			end
		
		end

		describe "ACCEPTANCE" do
			it "should accept string with constant repetition" do
				g = Grammy.define :simple do
					helper lower: 'a'..'z'
					start string: :lower * 4
				end

				['abcc','aaaa','cccc','acac','bbbb'].each { |str|
					g.parse(str).should be_success
				}
			end

			it "should accept string with optional rule" do
				g = Grammy.define :simple do
					rule a: 'a'
					start char: :a?
				end

				g.debug!
				
				#g.parse('').should be_success
				#g.parse('a').should be_success
				#g.parse('ac').should be_success
				g.parse('b').should be_fail
				g.parse('ba').should be_fail
			end

			it "should accept string with one or more characters" do
				g = Grammy.define :simple do
					helper lower: 'a'..'z'
					start string: +:lower
				end

				g.parse("somelongerstring").should be_success
			end

			it "should accept string with sequence" do
				g = Grammy.define :simple do
					helper lower: 'a'..'z'
					start string: :lower >> :lower >> :lower >> :lower
				end

				['abcc','aaaa','cccc','acac','bbbb'].each { |str|
					g.parse(str).should be_success
				}

				# TODO fail
			end

			it "should accept string with constant repetition in sequence" do
				g = Grammy.define :simple do
					helper lower: 'a'..'c'
					start string: :lower*3 >> :lower
				end
				
				['abcc','aaaa','cccc','acac','bbbb'].each { |str|
					g.parse(str).should be_success
				}

				# TODO fail
			end

			it "should accept an identifier" do
				g = Grammy.define :simple do
					helper lower: 'a'..'z'
					helper upper: 'A'..'Z'
					helper letter: :lower | :upper
					helper ident_start: :letter | '_';
					helper ident_letter: :ident_start | ('0'..'9')
					start ident: :ident_start >> (:ident_letter * (0..128))
				end
				
				['a','abc_abc_abc','abc_123_abc','some_id0'].each { |ident|
					g.parse(ident).should be_success
				}

				# TODO fail
			end

			it "should parse repetition" do
				g = Grammy.define :simple do
					rule string: 'abc' | '1234'
					start start: :string * (1..3)
				end

				[
					"1234abc",
					"abcabcabc",
					"12341234",
					"1234"
				].each{ |input|
					g.parse(input).should be_success
				}

				g.debug!

				[
					"",
					"1234ab",
					"123abc",
					"1234bc",
					"abc1234abcabc",
					"abcxyzabcabc"
				].each { |input|
					g.parse(input).should be_fail
				}
			end

			it "should parse all valid bit strings" do
				g = Grammy.define :simple do
					start start: ('0' | '1') * (1..3)
				end

				(0..8).each { |i|
					g.parse(i.to_s(2)).should be_success
				}

				[
					"",
					"0000",
					"012",
					"1011",
					"2",
					"000\n"
				].each { |input|
					g.parse(input).should be_fail
				}
			end
		end

	end

	describe "AST" do
		it "should parse string with constant repetition" do
			g = Grammy.define :simple do
				helper lower: 'a'..'z'
				start string: :lower * 4
			end

			tree = g.parse("some").ast_node

			tree.data.should == "some"
			tree.to_s.should == "string{'some'}\n"
			tree.children.should be_empty
		end

		it "should parse string with one or more characters" do
			g = Grammy.define :simple do
				helper lower: 'a'..'z'
				start string: +:lower
			end

			tree = g.parse("somelongerstring").ast_node

			tree.data.should == "somelongerstring"
			tree.to_s.should == "string{'somelongerstring'}\n"
			tree.children.should be_empty
		end

		it "should parse string with sequence" do
			g = Grammy.define :simple do
				helper lower: 'a'..'z'
				start string: :lower >> :lower >> :lower >> :lower
			end

			tree = g.parse("some").ast_node

			tree.data.should == "some"
			tree.match_range.should == (0..3)
			tree.children.should be_empty
		end
		
		it "should remove helper nodes" do
			g = Grammy.define :simple do
				helper lower: 'a'..'z'
				helper upper: 'A'..'Z'
				helper letter: :lower | :upper
				helper ident_start: :letter | '_';
				helper ident_letter: :ident_start | ('0'..'9')
				start ident: :ident_start >> (:ident_letter * (0..128))
			end

			tree = g.parse("some_id0").ast_node

			tree.to_s.should == "ident{'some_id0'}\n"
			tree.children.should be_empty
		end

		it "should only remove helper nodes" do
			g = Grammy.define :simple do
				rule id: ('a'..'z')*(1..10)
				helper part: :id >> ':' >> :id
				rule sent: :part >> '.'
				start start: :sent*(1..3)
			end
			
			tree = g.parse("ab:ac.kk:ee.").ast_node
			
			tree.data.should == "ab:ac.kk:ee."

			tree.children.length.should == 2
			sent1 = tree.children[0]
			sent2 = tree.children[1]

			sent1.name.should == :sent
			sent2.name.should == :sent
			sent1.data.should == "ab:ac."
			sent2.data.should == "kk:ee."
			
			sent1.children.map{|c| {c.name => c.data}}.should == [{id: 'ab'}, {id: 'ac'}]
			sent2.children.map{|c| {c.name => c.data}}.should == [{id: 'kk'}, {id: 'ee'}]
		end

		it "should parse string with constant repetition in sequence" do
			g = Grammy.define :simple do
				helper lower: 'a'..'z'
				start string: :lower*3 >> :lower
			end

			tree = g.parse("some").ast_node
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
				start ident: :ident_start >> (:ident_letter * (0..128))
			end

			tree = g.parse("some_id0").ast_node
			tree.should be_a AST::Node
			tree.data.should == "some_id0"
		end
	end

end
