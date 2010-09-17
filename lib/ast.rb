module AST

	class Node
		attr_reader :name, :range, :start_pos, :end_pos, :children, :stream
		attr_reader :source, :start_line, :end_line, :start_column, :end_column

		def initialize(name,options={})
			@name = name || 'anonymous'
			@children = []

			@start_pos, @end_pos = options[:range]
			@merge = options[:merge]
			@stream = options[:stream] || raise("no stream given")

			options[:children].each{ |child| add_child(child) } if options[:children]
			
			options.except(:merge,:stream,:children).each do |key,val|
				if respond_to?("#{key}=")
					send("#{key}=",val)
				else
					instance_variable_set("@#{key}",val)
				end
			end
		end

		# TODO add parent
		
		def line_range
			[start_line..end_line]
		end

		def range
			[@start_pos,@end_pos]
		end

		def length
			@end_pos - @start_pos
		end

		def data
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
		
		def get_children(name)
			raise("symbol expected but got: #{name.inspect}") unless name.is_a? Symbol
			@children.select{ |child| child.name == name }
		end
		
		def has_child?(name)
			get_children(name).any?
		end
		
		def method_missing(meth,*args)
			#@children.find{ |child| child.name == meth } || raise("no child named '#{meth}'")
			
			if /\?\Z/ === meth
				meth_name = meth[0..-2].to_sym
				get_children(meth_name).any?
			elsif /[^?!=]\Z/ === meth
				c = get_children(meth)
				if c.empty?
					raise("node #{name} has no child named '#{meth}'")
				else
					if c.one?
						if c.first.leaf_node?
							c.first.data
						else
							c.first
						end
					else
						c
					end
				end
			else
				super
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
