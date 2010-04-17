
gem 'rspec'

require 'Grammy'

describe "AST" do
	it "should parse string with constant repetition" do
		g = Grammy.define :simple do
			helper lower: 'a'..'z'
			start string: :lower * 4
		end

		tree = g.parse("some").tree

		tree.data.should == "some"
		tree.to_tree_string.should == "string{'some'}\n"
		tree.children.should be_empty
	end

	it "should parse string with one or more characters" do
		g = Grammy.define :simple do
			helper lower: 'a'..'z'
			start string: +:lower
		end

		tree = g.parse("somelongerstring").tree

		tree.data.should == "somelongerstring"
		tree.to_tree_string.should == "string{'somelongerstring'}\n"
		tree.children.should be_empty
	end

	it "should parse string with sequence" do
		g = Grammy.define :simple do
			helper lower: 'a'..'z'
			start string: :lower >> :lower >> :lower >> :lower
		end

		tree = g.parse("some").tree

		tree.data.should == "some"
		tree.range.should == [0,4]
		tree.children.should be_empty
	end

	it "should remove helper nodes" do
		g = Grammy.define :simple do
			helper lower: 'a'..'z'
			helper upper: 'A'..'Z'
			helper letter: :lower | :upper
			helper ident_start: :letter | '_';
			helper ident_letter: :ident_start | ('0'..'9')
			start ident: :ident_start >> ~:ident_letter
		end

		tree = g.parse("some_id0").tree

		tree.to_tree_string.should == "ident{'some_id0'}\n"
		tree.children.should be_empty
	end

	it "should only remove helper nodes" do
		g = Grammy.define :simple do
			rule id: ('a'..'z')*(1..10)
			helper part: :id >> ':' >> :id
			rule sent: :part >> '.'
			start start: :sent*(1..3)
		end

		tree = g.parse("ab:ac.kk:ee.").tree

		tree.data.should == "ab:ac.kk:ee."

		tree.should have(2).children
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

		tree = g.parse("some").tree
		tree.data.should == "some"
		tree.range.should == [0,4]
	end

	it "should parse an identifier" do
		g = Grammy.define :simple do
			helper lower: 'a'..'z'
			helper upper: 'A'..'Z'
			helper letter: :lower | :upper
			helper ident_start: :letter | '_';
			helper ident_letter: :ident_start | ('0'..'9')
			start ident: :ident_start >> ~:ident_letter
		end

		tree = g.parse("some_id0").tree
		tree.should be_a AST::Node
		tree.data.should == "some_id0"
	end

	it "should parse sequence grammar with skipper and not create nodes for skipper" do
		g = Grammy.define :simple do
			skipper whitespace: +(' ' | "\n" | "\t")

			token a: 'ab'
			start start: :a >> :a >> :a
		end

		match = g.parse("ab\nab\t  ab")
		root = match.tree

		match.should be_full_match
		root.data.should == "ab\nab\t  ab"
		root.name.should == :start
		root.should have(3).children
		root.children[0].name.should == :a
		root.children[0].data.should == 'ab'
	end

	it "should parse sequence grammar with skipper and create nodes for tokens" do
		g = Grammy.define :simple do
			skipper whitespace: +(' ' | "\n" | "\t")

			token a: 'ab' | 'xy'
			start start: :a >> :a >> :a
		end

		match = g.parse("ab\nxy\t  ab")
		root = match.tree

		match.should be_full_match
		root.data.should == "ab\nxy\t  ab"
		root.name.should == :start
		root.should have(3).children
		root.children[0].name.should == :a
		root.children[0].data.should == 'ab'
		root.children[1].name.should == :a
		root.children[1].data.should == 'xy'
	end
end