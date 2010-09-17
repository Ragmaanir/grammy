
module AST

	class Checker
	
		attr_reader :errors
	
		class CheckResult; end
		
		class Fail < CheckResult
			attr_accessor :errors
			
			def initialize(errors)
				@errors = errors
			end
		end
		
		class Success < CheckResult
		end
		
		# Expectation format for AST:
		# Expect a child-node named 'subnode' under root node named 'node'
		# 	node.subnode
		# Expect a node named 'descendant' somewhere below the node named 'subnode'
		# 	node.subnode.*.descendant
		# Expect the node named 'descendant' to have data 'value'
		# 	node_one.subnode.*.descendant { 'value' }
		# Expect 'sub_node' to have the specified value as well as several subnodes.
		# 	node.sub_node {
		# 		'str --> other str',
		# 		descendant { 'str' },
		# 		other_node.subnode { 'other str' }
		# 	}
		# Expect a node to have at least one child
		#	? { ? }
		# Expect that all children of the root node have children
		#	root { all: ?.? }
		
		#SpecGrammar = Grammy.define do
		#	default_skipper ws => /\s+/
		#	
		#	token	name => /[a-zA-Z_]+/
		#	token 	glob => '*'
		#	token	any	 => '?' # ignore name of node # needed?
		#	
		#	token	value_assertion => /'(\\(\\|')|[^\\'])*'/
		#	
		#	rule	quantifier		=> 'all:' | 'exists:'
		#	helper	path_item		=> name | glob | any
		#	rule	expectations	=> '{' & list(path_assertion | value_assertion) & '}'
		#	rule	path			=> list(path_item,'.')
		#	rule	path_assertion	=> quantifier? >> path >> expectations?
		#	start	start_assertion => path_assertion
		#end
		
		# FullASTSpecGrammar
		# ------------------
		# Used to specify a full AST with every node and its value.
		# *Examples*
		#
		# 	root.child { 'data' }
		# Matches:
		#	
		#	(root)--(child)--('data')
		#
		#	root {
		#		child_a { 'data' },
		#		child_b.subnode { 'data' }
		#	}
		# 
		# Matches:
		#		(child_a)--('data')
		#		/
		#	(root)--(child_b)--(subnode)--('data')
		#
		FullASTSpecGrammar = Grammy.define do
			default_skipper ws => /\s+/
			
			token	node_name => /[a-zA-Z_]+/
			
			token	value_assertion => /'(\\(\\|')|[^\\'])*'/
			
			rule	path_assertions	=> list(path_assertion)
			rule	expectations	=> '{' & path_assertions | value_assertion & '}'
			rule	path			=> list(node_name,'.')
			rule	path_assertion	=> path >> expectations?
			
			start	start_assertion => path_assertion
		end
		
		def self.check(ast,ast_spec)
			spec_parse_result = FullASTSpecGrammar.parse(ast_spec)
			
			if spec_parse_result.full_match? and not spec_parse_result.has_errors?
				# check path
				expected_ast = tree_from_spec(ast_spec)
				
				check_ast(ast,expected_ast)
			else
				Fail.new(spec_parse_result.errors)
			end
		end
		
		def check_ast(input_ast,expected_ast)
			raise unless input_ast.is_a? AST::Node
			raise unless expected_ast.is_a? AST::Node
			
			result = false
			err_msg = "#{input_ast.name} <-> #{expected_ast.name}"
			
			if input_ast.name != expected_ast.name
				errors << "#{err_msg} : name mismatch"
			elsif input_ast.children.length != expected_ast.children.length
				errors << "#{err_msg} : children count : #{input_ast.children.length} , #{expected_ast.children.length}"
			elsif input_ast.leaf_node?
				if input_ast.data != expected_ast.data
					errors << "#{err_msg} : data : '#{input_ast.data}' , '#{expected_ast.data}'"
				else
					result = true
				end
			else
				input_ast.children.each_with_index { |child,idx|
					return false if not check_ast(child,expected_ast.children[i])
				}
				
				return true
			end
		end
		
		def tree_from_spec(spec_root_node)
			raise unless spec_root_node.is_a? AST::Node
			raise unless spec_root_node.name == :path_assertion
			
			tree_root = AST::Node.new(spec_root_node.data)
			current_node = tree_root
			
			spec_root_node.children.each { |child|
				case child.name
					when :node_name
						new_node = AST::Node.new(child.data)
						current_node.add_child(new_node)
						current_node = new_node
					when :expectation
						if child.path_assertions?
							child.path_assertions.each { |assertion|
								current_node.add_child(tree_from_spec(assertion))
							}
						elsif child.value_assertion?
							current_node.data = child.value_assertion.data
						else raise
						end
					else raise
				end
			}
			
			tree_root
		end
		
=begin
		def traverse_path_assertion(ast_node,path_assertion_node)
			raise unless path_assertion_node.name == :path_assertion
			
			path = path_assertion_node.children.dup
			
			if path.first.name == :quantifier
				quantifier = path.shift.data.to_sym
			else
				quantifier = :exists
			end
			
			while path_node = path.shift
				case path_node.name
					when :name
						if ast_node.has_child?(path_node.data)
							ast_child = ast_node.get_children(path_node.data).first
						else
							@errors << "child '#{path_node.data}' missing in #{ast_node.name}"
							return Fail.new(@errors) if fail_fast?
						end
					when :glob
						
					when :any
					when :expectations # this is always the last child
					else raise "invalid child name: #{path_node.name}"
				end
			end
		end
		
		def traverse_path(ast_node,root_path_nodes)
			child_nodes = []
			case root_path_node.name
				when :name
					if ast_node.has_child?(path_node.data)
						ast_child = ast_node.get_children(path_node.data).first
					else
						@errors << "child '#{path_node.data}' missing in #{ast_node.name}"
						return Fail.new(@errors) if fail_fast?
					end
				when :glob
					
				when :any
				when :expectations # this is always the last child
				else raise "invalid child name: #{path_node.name}"
			end
		end
		
		def exists_path(path_node,ast_nodes)
			raise unless path_node.name == :path
			
			
			ast_nodes.each { |ast_node|
				case path_node.name
					when :name
						if ast_node.has_child?(path_node.data)
							ast_child = ast_node.get_children(path_node.data).first
						else
							@errors << "child '#{path_node.data}' missing in #{ast_node.name}"
							return Fail.new(@errors) if fail_fast?
						end
					when :glob
						
					when :any
					else raise "invalid child name: #{path_node.name}"
				end
			}
		end
=end

	end#Checker

end
