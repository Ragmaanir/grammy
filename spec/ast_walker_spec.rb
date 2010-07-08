
require 'spec/spec_helper'

describe "AST Walker should" do

	before do
		g = Grammy.define do
			default_skipper :skip => ~' '
		
			token :word => +('a'..'z')
			start :sent => +:word >> '.'
		end
		
		str = "firstword anotherword lastword."
		
		@ast = g.parse(str).tree
	end

	it "walk down AST" do
		
		walker = AST::Walker.build do
			before(:word) do |node|
				@x ||= 0
				@x += 1
			end
		end
		
		walker.walk(@ast)
	end
	
	it "walk down AST and store information in context" do
		ctx_cls = Class.new do
			attr_reader :words
			
			def initialize
				@words = []
			end
		end
		
		context = ctx_cls.new
		
		walker = AST::Walker.build(context) do
			before(:word) do |node|
				words << node.data
			end
		end
		
		walker.walk(@ast)
		
		context.words.should == "firstword anotherword lastword".split
	end
	
	it "walk down AST and use after-action" do
		g = Grammy.define do
			default_skipper :skip => ~' '
		
			token :bool_const => 'true' | 'false'
			token :int => ('1'..'9') >> ~('0'..'9')
			token :string => '"' & ~('a'..'z') & '"'
			
			rule :stat => :bool_const | :int | :string
			
			start :if_statement => 'if' & :bool_const & 'then' & :stat & 'else' & :stat & eos
		end
		
		str = %q{ if true then 1 else "asd" }
		
		ast_node_extension = Module.new do
			attr_accessor :type
		end
		
		@ast = g.parse(str, ast_module: ast_node_extension).tree
		
		ctx_cls = Class.new
		
		context = ctx_cls.new
		
		walker = AST::Walker.build(context) do
			after(:if_statement) do |node|
				node.type = node.children[1..-1].map{|c| c.type }.flatten
			end
			
			after(:stat) do |node|
				node.type = node.children.map{|c| c.type }.flatten
			end
			
			before(:bool_const) do |node|
				node.type = :bool
			end
			
			before(:int) do |node|
				node.type = :int
			end
			
			before(:string) do |node|
				node.type = :string
			end
		end
		
		walker.walk(@ast)
		
		@ast.type.should == [:int,:string]
	end
	
end
