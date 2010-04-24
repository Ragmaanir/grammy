Grammy
======

Description
-----------
Grammy is a DSL that generates recursive descent parsers. The DSL is inspired by
the boost::spirit parser framework for c++.

Features
--------

- Most EBNF features: Sequences, Repetition, Alternatives, Optional rules
- Shortcut for lists: `list` and `list?`
- Skipping of characters: comments, whitespaces between words
- Generation of an AST. Most unused tokens can be removed automatically.
- AST can be written to an image file with help of graphviz.

Todo
----

- Error handling: disable backtracking with the `/` operator
- Subtraction: +('a'..'z') - 'reserved'
- semantic actions
- validation (rules which never match, left recursion)
- much more: see doc/todo.txt

Define a grammar
----------------

### Sequences
The following BNF grammar:

	<token> ::= 'test' 'other'

can be defined in grammy like this:

	g = Grammy.define :simple do
		rule token: 'test' >> 'other'
	end

The `>>` is the sequence operator which indicates that the string `'test'`
should be followed by the string `'other'`.


### Alternatives
The BNF grammar:

	<lower> ::= 'a' | 'b' | .. | 'z'

can be defined like this:

	g = Grammy.define :lower_chars do
		rule lower: 'a' | 'b' | .. | 'z'
	end

or shorter:

	g = Grammy.define :lower_chars do
		rule lower: 'a'..'z'
	end

So the range is a shortcut.

### Repetition
The following BNF grammar:

	<digits> ::= (1 | 2 | .. | 9)+

can be defined like this:

	g = Grammy.define :digit_grammar do
		rule digits: +('1'..'9')
	end

So the `+` operator (Kleene-cross) has just to be in front of the subrule that should be repeated.
The `~` operator used in grammy is the equivalent to the kleene-star (0..infinite repetitions).
Like the `+` operator, `~` has to stand in front of the rule that should be repeated.
Constant repetition like `'a' * 4` and ranged repetition like `'a' * (0..7)` is
also possible (`+`, `~` and constant repetitions are just special cases of ranged repetitions).

### Multiple rules

The following BNF grammar with multiple rules:

	<lower> ::= 'a' | .. | 'z'
	<upper> ::= 'A' | .. | 'Z'
	<letter> ::= <lower> | <upper>
	<word> ::= <letter>+

is defined like this:

	g = Grammy.define :letters do
		rule lower: 'a'..'z'
		rule upper: 'A'..'Z'
		rule letter: :lower | :upper
		rule word: +:letter
	end

### Optional rules
The following BNF grammar with an optional rule:

	<optional> ::= ['a']

is defined like this:

	g = Grammy.define :letters do
		rule a: 'a'
		rule optional: :a?
	end

So you just have to append a `?` to the name of the rule.

### EOS Rule

You can use the `eos` rule to match the end of a string:

	g = Grammy.define :eos do
		start words: 'hello' >> 'world' >> eos
	end

### List Rule

Lists are things that often occur in grammars, e.g. a parameter list:

	g = Grammy.define :list do
		rule item: ('a'..'z')*(2..8)
		start start: :item >> ~(',' >> :item)
	end

Since this occurs very often and is not very readable, there is a shortcut for lists:

	g = Grammy.define :list do
		rule item: ('a'..'z')*(2..8)
		start start: list(:item)
	end

The seperator can be specified with the second parameter of `list` (default is ',').

Parsing
-------
You can use the defined grammar to parse strings:

	g = Grammy.define :letters do
		rule lower: 'a'..'z'
		rule upper: 'A'..'Z'
		rule letter: :lower | :upper
		rule word: +:letter
	end
	
	result = g.parse("someword", rule: :word)
	result.full_match? #=> true

	result = g.parse("someword", rule: :letter)
	result.full_match? #=> false
	result.partial_match? #=> true

Most grammars have a start rule. You can set that start rule inside the grammar:

	g = Grammy.define :letters do
		rule lower: 'a'..'z'
		rule upper: 'A'..'Z'
		rule letter: :lower | :upper
		start word: +:letter # this is now the start rule
	end

The rule `:word` is now the start rule. If no rule is supplied to `parse`, then the start rule is used.

Skipping
--------
Often you want to skip several parts of the grammar (e.g whitespaces or comments).
Thats what a skipper does:

	g = Grammy.define :words do
		skipper whitespacs: +' '
		start words: 'hello' >> 'world'
	end

The skipper now skips whitespaces when parsing:

	g.parse("hello        world").full_match? #=> true
	g.parse("helloworld").no_match? #=> true

You dont want to skip in every rule. Skippers are disabled when you declare the rule as `token`:

	g = Grammy.define :words do
		skipper whitespacs: +' '
		token word: +('a'..'z') # no skipping between the characters
		start words: 'hello' >> 'world' >> :word
	end

AST Generation
--------------
When parsing a string an abstract syntax tree is generated for the string:

![image of example AST](http://ragmaanir.mypresident.de/images/example_ast.png)

The AST can be accessed like this:

	t = g.parse("helloworld").tree
	t.data #=> "helloworld", the string that got matched by this node
	t.children #=> array of child nodes

To output the AST there are two methods:

 - as string: `tree.to_string_tree`
 - as image: `tree.to_image('my_ast')` # graphviz required. default output format is '.png'

Many substrings that are matched by the grammar are automatically *not* included in the AST:

- characters matched by a skipper
- rules without a name dont create AST-Nodes:

	`rule a: +('a'-'z')`

	This creates only *one* node for the rule 'a'. Not one for each character.

Debuggin
--------

You can see what the parser is doing when you turn debugging on:

	g.parse("some input", debug: true)


Testing
-------

There are several rspec test which might inspire you (e.g. common_grammars_spec.rb).

For very complex grammars you can do something like this:

#### `your_grammar_spec.yaml`
	-
	  name: "Empty class"
	  code: |
		  class EmptyClass {
		  }
	-
	  name: "Class with variable"
	  code: |
		  class VarCls {
			var x : Int = 3
		  }

#### `your_grammar_spec.rb`
	describe "YAML specs: " do
		yaml_specs = YAML.load_file('spec/spec.yaml')

		yaml_specs.each do |spec|
			it spec['name'] do
				if not @grammar.parse(spec['code']).full_match?
					raise RuntimeError, "failed"
					# maybe supply File.dirname(__FILE__)+'/spec.yaml:#{line_number}'
				end
			end
		end
	end

You basically define lots of valid example input in a yaml file an test if each of them is a full match.
