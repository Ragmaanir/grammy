class AST

	class Node
		attr_accessor :name, :children, :range, :start_pos, :end_pos
		attr_reader :stream

		def initialize(name,options={})
			@name = name || 'anonymous'
			@children = options[:children] || []
			@start_pos, @end_pos = options[:range]
			@merge = options[:merge]
			@stream = options[:stream] || raise("no stream given")
		end

		def range
			#@range || raise("no match range")
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
				#@children = @children + node.children
				@children.concat(node.children)
			else
				@children << node
			end
		end

		def to_s(indents=0)
			indent = "  "*indents

			result = ""
			result << indent + "#{@name}"
			
			if leaf_node?
				result << "{'#{data}'}"
			else
				result << "{ \n"
				result << @children.map{ |c|
						if c.is_a? Node
							c.to_s(indents+1)
						else
							c.to_s
						end
					}.join("\n")
				result << indent + "}"
			end

			result << "\n"
			
			result
		end
	end

end