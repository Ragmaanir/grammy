class AST

	class Node
		attr_accessor :name, :children, :range, :start_pos, :end_pos
		attr_reader :stream

		def initialize(name,options={})
			@name = name || 'anonymous'
			@children = []
			options[:children].each{ |child| add_child(child) } if options[:children]

			@start_pos, @end_pos = options[:range]
			@merge = options[:merge]
			@stream = options[:stream] || raise("no stream given")
		end

		def range
			[@start_pos,@end_pos]
		end

		def length
			@end_pos - @start_pos
		end

		def data
			raise "node '#{name}' has no stream" unless stream
			@stream[@start_pos,length]
		end

		def leaf_node?
			@children.empty?
		end

		def merge=(value)
			raise("invalid value for merge: '#{value}'") unless [true,false].include? value
			@merge = value
		end
		
		def merge?
			@merge
		end

		def add_child(node)
			raise "node is nil" if node.nil?
			raise "node is no Node: '#{node}'" unless node.is_a? Node
			if node.merge?
				@children.concat(node.children)
			else
				@children << node
			end
		end

		# 
		def to_tree_string(indents=0)
			indent = "  "*indents

			result = ""
			result << indent + "#{@name}"
			
			if leaf_node?
				result << "{'#{data}'}"
			else
				result << "{ \n"
				result << @children.map{ |c|
						if c.is_a? Node
							c.to_tree_string(indents+1)
						else
							c.to_s
						end
					}.join("\n")
				result << indent + "}"
			end

			result << "\n"
			
			result
		end

		#
		def to_image(name,format=:png)
			require 'graphviz'
			
			graph = GraphViz.new(name)
			graph.node[shape: :box, fontsize: 8]

			queue = []

			root = graph.add_node(self.object_id.to_s, label: self.name)
			queue << [self,root]

			while queue.any?
				cur_node,graph_node = queue.pop

				if cur_node.leaf_node?
					new_node = graph.add_node(cur_node.data.object_id.to_s, label: "'#{cur_node.data}'")
					new_node[shape: :circle, style: :filled, fillcolor: "#6699ff", fontsize: 8]
					graph.add_edge(graph_node,new_node)
				else
					cur_node.children.each { |child|
						new_node = graph.add_node(child.object_id.to_s, label: child.name)
						graph.add_edge(graph_node,new_node)
						queue << [child,new_node]
					}
				end
			end

			graph.save(format => "temp/#{name}.#{format}")

		end

	end

end