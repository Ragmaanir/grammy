
module AST

	#
	#
	class Walker

		#attr_reader :node_handlers
		attr_reader :before_handlers, :after_handlers
		
		def initialize(options)
			#@node_handlers = options[:handlers] || raise
			@before_handlers = options[:before_handlers] || raise
			@after_handlers = options[:after_handlers] || raise
			@context = options[:context]
			#@node_stack = []
		end
		
		def method_missing(meth,*args)
			raise("unknown method: #{meth}") unless @context
			@context.send(meth,*args)
		end
		
=begin
		def descend!
			@node_stack.last.children.each{ |child| walk(child) }
		end
		
		def walk(ast_node)
			@node_stack.push(ast_node)
			
			block = @node_handlers[ast_node.name]
			
			#descended = false
			#descended = 
			instance_exec(@node_stack.last,&block) if(block)
			
			descend! #unless descended
			
			@node_stack.pop
		end
=end

		def walk(ast_node)
			raise "ast node expected but was: #{ast_node.class}" unless ast_node.is_a? AST::Node
			traverse(ast_node)
		end
		
		def traverse(root_node)
			iteratively_traverse(root_node,->(node){
				block = @before_handlers[node.name]
				self.instance_exec(node,&block) if block
			},
			->(node){
				block = @after_handlers[node.name]
				self.instance_exec(node,&block) if block
			})
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
		
		
		def self.build(context=nil,options={},&block)
			options = options.merge(context: context)
			Builder.new(options,&block).built_walker
		end
		
		# 
		# 
		# 
		class Builder

			def initialize(options={},&block)
				#@node_handlers = {}
				@before_handlers = {}
				@after_handlers = {}
				
				instance_eval(&block)
				
				options = options.merge(
								before_handlers: @before_handlers, 
								after_handlers: @after_handlers)
				#options = options.merge(handlers: @node_handlers)
				@walker = Walker.new(options)
			end
			
			def built_walker
				@walker
			end
			
			#def with(ast_node,&block)
			#	raise unless ast_node.is_a? Symbol
			#	raise if @node_handlers[ast_node]
			#	
			#	@node_handlers[ast_node] = block
			#end
			
			def before(ast_node,&block)
				raise "expected symbol, got #{ast_node.class}" unless ast_node.is_a? Symbol
				raise "before-handler #{ast_node} already present" if @before_handlers[ast_node]
				
				@before_handlers[ast_node] = block
			end
			
			def after(ast_node,&block)
				#raise unless ast_node.is_a? Symbol
				#raise if @after_handlers[ast_node]
				raise "expected symbol, got #{ast_node.class}" unless ast_node.is_a? Symbol
				raise "after-handler #{ast_node} already present" if @after_handlers[ast_node]
				
				@after_handlers[ast_node] = block
			end
			
		end#Builder
		
	end#Walker

end#AST
