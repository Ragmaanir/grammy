
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

		it "should define grammar with StringRule" do
			g = Grammy.define :simple do
				rule token: 'test'
			end

			token = g.rules[:token]
			token.should be_a Grammar::StringRule
			token.children.should be_empty
			token.string.should == "test"
		end

		it "should define grammar with optional rule" do
			g = Grammy.define :simple do
				rule a: 'a'
				rule b: 'b'
				rule phrase: :a? >> :b
			end

			phrase = g.rules[:phrase]
			phrase.should be_a Grammar::Sequence
			phrase.should have(2).children
			phrase.children.first.should be_a Grammar::RuleWrapper
			phrase.children.first.should be_optional
		end

		it "should define grammar with list-helper" do
			g = Grammy.define :simple do
				rule item: ('a'..'z')*(2..8)
				start phrase: list(:item)
			end

			phrase = g.rules[:phrase]
			phrase.should be_a Grammar::Sequence
			phrase.should have(2).children
			
			phrase.children[0].should be_a Grammar::RuleWrapper
			phrase.children[0].rule.should == g.rules[:item]

			phrase.children[1].should be_a Grammar::Repetition
			phrase.children[1].repetitions.should == (0..1000)
			phrase.children[1].should have(1).children

			params = phrase.children[1].children[0]
			params.should be_a Grammar::Sequence
			params.should have(2).children
			params.children[0].should be_a Grammar::StringRule
			params.children[1].should be_a Grammar::RuleWrapper
			params.children[1].rule.should == g.rules[:item]
		end

		it "should define grammar with helper rule" do
			g = Grammy.define :simple do
				helper a: 'a'
				rule b: 'b'
				rule phrase: :a >> :b
			end

			phrase = g.rules[:phrase]
			
			phrase.should be_a Grammar::Sequence
			phrase.should have(2).children
			phrase.children.each{|child| child.should be_a Grammar::RuleWrapper }

			g.rules[:a].should be_helper
			g.rules[:b].should_not be_helper
			
			phrase.children[0].rule.should == g.rules[:a]
			phrase.children[1].rule.should == g.rules[:b]
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
				node.range.should == [0,1]
				node.name.should == :lower
			end

			it "should match one or more characters" do
				g = Grammy.define :simple do
					helper lower: 'a'..'z'
					rule string: +:lower
				end

				node = g.rules[:string].match("some",0).ast_node
				node.should be_a AST::Node
				node.data.should == "some"
				node.range.should == [0,4]
				node.name.should == :string
			end

			it "should match string without helper" do
				g = Grammy.define :simple do
					rule lower: 'a'..'z'
					rule string: +:lower
				end
				
				node = g.rules[:string].match("some",0).ast_node
				
				node.should be_a AST::Node
				node.name.should == :string
				node.range.should == [0,4]
				node.to_tree_string.should_not == "string{'some'}\n"
				node.should have(4).children
				node.children.first.to_tree_string.should == "lower{'s'}\n"
			end

			it "should merge helper nodes" do
				g = Grammy.define :simple do
					helper lower: 'a'..'z'
					rule string: +:lower
				end

				node = g.rules[:string].match("some",0).ast_node
				node.data.should == "some"
				node.range.should == [0,4]
				node.children.should be_empty
				node.to_tree_string.should == "string{'some'}\n"
			end
		
		end

		describe "ACCEPTANCE" do

			it "should parse comma seperated list" do
				g = Grammy.define :list do
					rule item: ('a'..'z')*(2..8)
					start start: :item >> ~(',' >> :item)
				end

				g.parse("").should be_no_match

				[
					"first",
					"first,second",
					"first,second,third"
				].each { |input|
					g.parse(input).should be_full_match
				}
			end

			it "should parse comma seperated list with list-helper" do
				g = Grammy.define :list do
					rule item: ('a'..'z')*(2..8)
					start start: list(:item)
				end

				g.parse("").should be_no_match

				[
					"first",
					"first,second",
					"first,second,third"
				].each { |input|
					g.parse(input).should be_full_match
				}
			end

			it "should parse and only skip in rules" do
				g = Grammy.define :simple do
					skipper whitespace: +(' ' | "\n" | "\t")

					token a: 'ab d'
					start start: +:a
				end

				g.parse("ab d\t\n ab d").should be_full_match
			end
		end

		describe "Error detection" do

			it "should raise in sequence" do
				g = Grammy.define :simple do
					helper lower: 'a'..'z'
					start string: :lower >> :lower / :lower >> :lower
				end

				g.rules[:string].should have(2).children
				g.rules[:string].should_not be_backtracking

				expect{ g.parse("aa1a") }.to raise_exception(Grammy::ParseError)
				expect{ g.parse("aaa3") }.to raise_exception(Grammy::ParseError)
			end

		end

	end

end
