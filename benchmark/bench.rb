
require 'benchmark'
require 'ruby-prof'

require 'Grammy'

#Benchmark::Suite.define do
#	benchmark "" do
#		
#	end
#end

class Array
	def random_element
		self[rand(length)]
	end
end

class String
	def self.random(alphabet=('a'..'z').to_a + ('A'..'Z').to_a,max_length=8,min_length=1)
		rand_len = rand(max_length-min_length)+min_length
		#rand_max = rand(max_length-min_length)
		#(min_length..rand_max).inject(""){ |s| s << alphabet.random_element }
		rand_len.times.inject(""){ |s| s << alphabet.random_element }
	end
end

g = Grammy.define do
	#default_skipper ws => +(' ' | '\t' | '\n')
	default_skipper ws => /\s+/

	#fragment letter => ('a'..'z') | ('A'..'Z')
	#fragment digit => '0'..'9'
	
	#token item => letter >> ~(letter | digit)
	token item => /[a-zA-Z][a-zA-Z0-9]*/
	start item_list => list(item)
end

letters = ('a'..'z').to_a + ('A'..'Z').to_a

number = 1_000

if false
Benchmark.bmbm do |b|
	b.report("new"){ number.times.map{1} }
	b.report("old"){ (0..number).map{1} }
end
end

input = (1..number).map{ String.random(letters) }.join(",  ")

res = nil

#Benchmark.bmbm do |b|
#	b.report { res = g.parse(input) }
#end

profile_result = RubyProf.profile do
	res = g.parse(input)
end

printer = RubyProf::GraphHtmlPrinter.new(profile_result)
File.open('temp/ruby-prof.html','w'){ |file| printer.print(file, min_percent: 1)}

p res.match
p res.range
p input.length
p input[res.end_pos-5,10]
