
module AST

	# The AST::Walker is used to traverse an Abstract Syntax Tree. 
	# The AST is traversed top-down and left-to-right. For each node 
	# visited before_handlers[node.name] and after_handlers[node.name] 
	# are called. Before handlers are called when the walker first visits 
	# the node (childnodes have not been visited yet). After-handlers are 
	# called when all descendant nodes have been visited and the walker 
	# leaves the node to traverse back to the parent node.
	#
	# Use AST::Walker#build to create an AST::Walker with a simple DSL.
	class Walker

		attr_reader :before_handlers, :after_handlers
		
		def initialize(options)
			@before_handlers = options[:before_handlers] || raise
			@after_handlers = options[:after_handlers] || raise
			@context = options[:context]
		end
		
		def method_missing(meth,*args)
			raise("unknown method: #{meth}") unless @context
			@context.send(meth,*args)
		end

		def walk(ast_node)
			raise "ast node expected but was: #{ast_node.class}" unless ast_node.is_a? AST::Node
			traverse(ast_node)
		end
		
		def traverse(root_node)
			iteratively_traverse(root_node,->(node){
					block = @before_handlers[node.name.to_sym]
					self.instance_exec(node,&block) if block
				},
				->(node){
					block = @after_handlers[node.name.to_sym]
					self.instance_exec(node,&block) if block
				}
			)
		end
		
		def iteratively_traverse(root_node,before_callback,after_callback)
			raise "ast node expected but was: #{root_node.class}" unless root_node.is_a? AST::Node
			raise "no before callback given" unless before_callback
			raise "no after callback given" unless after_callback
			
			path_stack = [root_node]
			
			unvisited_nodes = {root_node => root_node.children.dup}
			
			while(path_stack.any?)
				node = path_stack.last#top
				
				if unvisited_nodes[node].any?
					child = unvisited_nodes[node].shift
					
					before_callback.call(child)
					
					path_stack.push(child)
					unvisited_nodes[child] = child.children.dup
				else
					unvisited_nodes.delete node
					top_node = path_stack.pop
					
					after_callback.call(top_node)
				end
			end
		end
		
		def to_s
			str = [
					"AST::Walker {",
					(before_handlers.keys + after_handlers.keys).collect { |key|
						handlers = []
						handlers << :before if before_handlers.has_key? key
						handlers << :after if after_handlers.has_key? key
						"\t#{key}: \t[#{handlers.join(',')}]"
					}.join("\n"),
					"}"
				].join("\n")
			str
		end
		
		
		# Build an instance of AST::Walker by using the AST::Walker::Builder
		# and its simple DSL.
		def self.build(context=nil,options={},&block)
			options = options.merge(context: context)
			Builder.new(options,&block).built_walker
		end
		
		# This Builder is used to construct an instance of AST::Walker with
		# the help of a very readable DSL:
		#
		# 	my_context = class Context
		#		def add_class(name); ... ;end
		#		def close_class(name); ... ;end
		#		def current_class; ... ;end
		#	end.new
		#	
		# 	AST::Walker::Builder.new(context: my_context) do
		# 	
		# 		before(:class_def) do |class_def|
		# 			add_class(class_def[:class_name]) # create a new empty class
		# 		end
		#		
		#		after(:class_def) do |class_def|
		#			close_class(class_def[:class_name]) # adding attributes and methods is finished now
		#		end
		#
		#		after(:attribute_def) do |attr_def|
		#			current_class.add_attribute(attr_def[:attr_name],...)
		#		end
		# 	end
		# 
		class Builder

			def initialize(options={},&block)
				@before_handlers = {}
				@after_handlers = {}
				
				instance_eval(&block)
				
				options = options.merge(
								before_handlers: @before_handlers, 
								after_handlers: @after_handlers)
				
				@walker = Walker.new(options)
			end
			
			def built_walker
				@walker
			end
			
			# The block that is passed gets called on every AST node whose 
			# name is included in the ast_nodes array. The block is called 
			# when the AST::Walker reaches the node by traversing the tree 
			# top-down & left-to-right.
			def before(*ast_nodes,&block)
				ast_nodes.each do |node|
					raise "expected symbol, got #{node.inspect}" unless node.is_a? Symbol
					raise "before-handler #{node} already present" if @before_handlers[node]
					
					@before_handlers[node] = block
				end
			end
			
			# This methods does the same as the #before with the exception 
			# that the passed block is called after the node has already been 
			# visited by a before handler. So all nodes below the visited 
			# node have already been visited by a before handler.
			def after(*ast_nodes,&block)
				ast_nodes.each do |node|
					raise "expected symbol, got #{node.inspect}" unless node.is_a? Symbol
					raise "after-handler #{node} already present" if @after_handlers[node]
					@after_handlers[node] = block
				end
			end
			
		end#Builder
		
	end#Walker

end#AST
