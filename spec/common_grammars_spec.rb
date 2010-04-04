
gem 'rspec'

require 'Grammy'

describe "CommonGrammars" do

	it "should define parameter list" do
		g = Grammy.define :param_list do
			skipper ws: +' '
			rule item: +('a'..'z')
			start list: list(:item,',')
		end

		g.parse("a, b, c").should be_full_match
		g.parse(" a").should be_full_match

		g.parse("a, b, 3").should be_partial_match
		g.parse("a, , b").should be_partial_match

		g.parse("\ta, b").should be_no_match
		g.parse("A, b").should be_no_match
		g.parse(", b").should be_no_match
		g.parse("").should be_no_match
	end

	it "should define identifier" do
		g = Grammy.define :identifier do
			helper lower: 'a'..'z'
			helper upper: 'A'..'Z'
			helper letter: :lower | :upper
			helper ident_start: :letter | '_';
			helper ident_letter: :ident_start | ('0'..'9')
			start ident: :ident_start >> (:ident_letter * (0..128))
		end

		g.parse("a").should be_full_match
		g.parse("some_id").should be_full_match
		g.parse("some_id0").should be_full_match
		g.parse("s0m3_1d0_").should be_full_match
		g.parse("_").should be_full_match

		g.parse("some_id0@").should be_partial_match
		g.parse("some-id0").should be_partial_match

		g.parse("-a").should be_no_match
		g.parse("0a").should be_no_match
	end

	it "should define integer" do
		g = Grammy.define :int do
			helper digit: '0'..'9'
			helper nonzero: '1'..'9'
			start int: '0' | :nonzero >> ~:digit
		end

		g.parse("12345678990").should be_full_match
		g.parse("0").should be_full_match

		g.parse("054").should be_partial_match

		g.parse("a09").should be_no_match
		g.parse("").should be_no_match
	end

	it "should define float" do
		g = Grammy.define :float do
			rule sign: '+' | '-'
			helper digit: '0'..'9'
			helper nonzero: '1'..'9'
			helper places: '.' >> +:digit
			start float: :sign? >> ('0' | :nonzero >> ~:digit) >> :places?
		end

		g.parse("0.0").should be_full_match
		g.parse("0").should be_full_match
		g.parse("12.0").should be_full_match
		g.parse("45.05300500").should be_full_match
		g.parse("-0.0").should be_full_match

		
		g.parse("05.0").should be_partial_match
		g.parse("0.").should be_partial_match

		g.parse("+-0.0").should be_no_match
		g.parse(".0").should be_no_match
	end

	it "should define float with exponent"

	it "should define quoted string" do
		g = Grammy.define :quoted_string do
			skipper ws: +' '

			helper letter: ('a'..'z') | ('A'..'Z')
			helper digit: '0'..'9'

			token string: '"' >> +(:letter | :DIGIT) >> '"'
			start quoted_string: :string
		end

		fail "implement '-' operator"

		g.parse(' " some text here" ').should be_full_match
		g.parse(' " some symbols here$&57/-., " ').should be_full_match
		g.parse(' " " ').should be_full_match
		g.parse(' "" ').should be_full_match

		g.parse(' "a" a').should be_partial_match
	end

	it "should define comments"

	it "should define arithmetic expressions" do
		g = Grammy.define :float do
			skipper ws: +' '

			token add: '+' | '-'
			token mult: '*' | '/'

			helper digit: '0'..'9'
			helper nonzero: '1'..'9'
			token int: '0' | :nonzero >> ~:digit

			rule lit: :int
			token var: +('a'..'z')
			rule unary_exp: :var | :lit
			rule add_exp: :unary_exp >> ~(:add >> :unary_exp)
			rule mult_exp: :add_exp >> ~(:mult >> :add_exp)

			start expression: :mult_exp
		end

		g.parse("5").should be_full_match
		g.parse("5 + 3").should be_full_match
		g.parse("5 + 23 * val").should be_full_match
		g.parse("5 * 3 / val").should be_full_match

		g.parse("5 + 23 * val").tree.to_image('expression')

		g.parse("5 * 3 / val 3").should be_partial_match
		g.parse("5 3").should be_partial_match

		g.parse("").should be_no_match
		g.parse(".").should be_no_match
	end

	it "should parse all valid bit strings" do
		g = Grammy.define :bit_strings do
			start start: ('0' | '1') * (1..3)
		end

		(0..7).each { |i|
			g.parse(i.to_s(2)).should be_full_match
		}

		["0000", "012", "1011", "000\n"].each{ |input|
			g.parse(input).should be_partial_match
		}

		["", "2"].each { |input|
			g.parse(input).should be_no_match
		}
	end

end