class AST

	class Node
		attr_accessor :name, :children
		attr_reader :match_range, :stream

		def initialize(name,options={})
			@name = name || 'anonymous'
			@children = options[:children]
			@match_range = options[:match_range]
		end

		def stream= (stream)
			@stream = stream
			@children.each { |c|
				c.stream = stream if c.is_a? Node
			}
		end

		def data
			stream[@match_range]
		end

		def to_s(indents=0)
			indent = "  "*indents

			result = ""
			result << indent + "#{@name}"
			
			if @children.is_a? Array
				result << "{ \n"
				result << @children.map{ |c|
						if c.is_a? Node
							c.to_s(indents+1)
						else
							c.to_s
						end
					}.join("\n")
				result << indent + "}"
			else
				result << "{'#{@children}'}"
			end

			result << "\n"
			
			result
		end
	end

end