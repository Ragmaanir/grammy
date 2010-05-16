
require 'spec/spec_helper'

describe Grammy do

	describe "should define" do

		it "empty grammar" do
			g = Grammy.define :simple do

			end

			g.name.should == :simple
			g.rules.should be_empty
		end

		it "grammar with list-helper" do
			g = Grammy.define do
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

		it "grammar with helper rule" do
			g = Grammy.define do
				helper a: 'a'
				rule b: 'b'
				rule phrase: :a >> :b
			end

			phrase = g.rules[:phrase]
			
			phrase.should be_a Grammar::Sequence
			phrase.should have(2).children
			phrase.children.each{|child| child.should be_a Grammar::RuleWrapper }

			g.rules[:a].should be_merging_nodes
			g.rules[:b].should_not be_merging_nodes
			
			phrase.children[0].rule.should == g.rules[:a]
			phrase.children[1].rule.should == g.rules[:b]
		end

		it "should have multiple skippers" do
			g = Grammy.define do
				skipper a: 'a'
				skipper b: 'b'
			end

			g.should have(2).skippers
			g.default_skipper.should == nil
		end

		it "should use default skipper when provided" do
			g = Grammy.define do
				skipper a: 'a'
				default_skipper default: ' '
				skipper b: 'b'
				
				start s: 'test'
			end
			
			g.default_skipper.should == g.rules[:default]
			g.rules[:s].skipper.should == g.default_skipper
		end

		it "skippers should neither skip nor generate ast" do
			g = Grammy.define do
				skipper a: 'a'
				default_skipper default: ' '
				skipper b: 'b'

				start s: 'test'
			end

			g.should have(3).skippers
			g.skippers.each { |_,s|
				s.should_not be_using_skipper
				s.should_not be_generating_ast
			}
		end

		it "should assign custom skipper to a rule" do
			g = Grammy.define do
				skipper a: 'a'
				default_skipper default: ' '

				start s: 'test', skipper: :a
			end

			g.rules[:s].skipper.should == g.skippers[:a]
		end

		it "grammar with duplicate rules and raise" do
			expect{
				Grammy.define do
					rule a: 'a'
					rule a: 'b'
				end
			}.to raise_error
		end

	end

	describe "should parse" do

		it "comma seperated list" do
			g = Grammy.define do
				rule item: ('a'..'z')*(2..8)
				start start: :item >> ~(',' >> :item)
			end

			g.should not_match('')

			g.should fully_match(
				"first",
				"first,second",
				"first,second,third"
			)
		end

		it "comma seperated list with list-helper" do
			g = Grammy.define do
				rule item: ('a'..'z')*(2..8)
				start start: list(:item)
			end

			g.should not_match('')

			g.should fully_match(
				"first",
				"first,second",
				"first,second,third"
			)
		end

		it "optional comma seperated list with list-helper" do
			g = Grammy.define do
				rule item: ('a'..'z')*(2..8)
				start start: list?(:item)
			end

			g.should fully_match(
				"",
				"first",
				"first,second",
				"first,second,third"
			)
		end

		it "and only skip in rules" do
			g = Grammy.define do
				default_skipper whitespace: +(' ' | "\n" | "\t")

				token a: 'ab d'
				start start: +:a
			end

			g.should fully_match("ab d\t\n ab d")
		end

		it "with specified skippers" do
			g = Grammy.define do
				default_skipper a_skipper: ~'a'
				skipper b_skipper: ~'b'

				rule content: +'+', skipper: :b_skipper
				start start: '{' >> :content >> '}'
			end

			g.should fully_match("aaa{aabb+bbbb+baa}")
			g.should not_match("aaa{aabb+abaa}")
		end

		it "should modify ast node" do
			g = Grammy.define do
				rule a: 'abc'
				rule b: :a | 'fail' , modify_ast: lambda{|node| node.children.first }
				rule c: :b | 'fail' , modify_ast: lambda{|node| node.children.first }
				start start: :c | 'fail'
			end

			ast = g.parse('abc').tree
			ast.should have(1).children
			ast.children.first.name.should == :a
		end

	end

end
