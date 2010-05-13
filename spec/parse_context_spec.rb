
require 'spec/spec_helper'

describe Grammy::ParseContext do

	it "should initialize context" do
		c = Grammy::ParseContext.new(nil,nil,"line1\nline2\n\n   line4")

		c.position.should == 0
		c.line_number.should == 1
		c.line_start.should == 0
		c.column.should == 0
		c.line.should == "line1"
	end
	
	it "should keep line number when moving position inside line" do
		c = Grammy::ParseContext.new(nil,nil,"line1\nline2\n\n   line4")

		c.position += 2
		c.line_number.should == 1
		c.line_start.should == 0
		c.column.should == 2
		c.line.should == "line1"
	end

	it "should adjust line number when moving position to next line" do
		c = Grammy::ParseContext.new(nil,nil,"line1\nline2\n\n   line4")

		c.position += 6
		c.line_number.should == 2
		c.line_start.should == 6
		c.column.should == 0
		c.line.should == "line2"
	end

	it "should adjust line number when moving position back to previous line" do
		c = Grammy::ParseContext.new(nil,nil,"line1\nline2\n\n   line4")

		c.position += 6
		c.line_number.should == 2
		c.line_start.should == 6
		c.column.should == 0
		c.line.should == "line2"

		c.position -= 2
		c.line_number.should == 1
		c.line_start.should == 0
		c.column.should == 4
		c.line.should == "line1"
	end

	it "should adjust line number when moving position back to start of stream" do
		c = Grammy::ParseContext.new(nil,nil,"line1\nline2\n\n   line4")

		c.position += 12
		c.line_number.should == 3
		c.line_start.should == 12
		c.column.should == 0
		c.line.should == ""

		c.position -= 12
		c.line_number.should == 1
		c.line_start.should == 0
		c.column.should == 0
		c.line.should == "line1"
	end

	it "should adjust line number when moving position to end of stream" do
		c = Grammy::ParseContext.new(nil,nil,"\n\n\n\n")

		c.position += 3
		c.line_number.should == 4
		c.line_start.should == 3
		c.column.should == 0
		c.line.should == ""
	end

	it "should adjust line number when moving position between empty lines" do
		c = Grammy::ParseContext.new(nil,nil,"\n\n\n\n")

		c.position += 1
		c.line_number.should == 2
		c.line_start.should == 1
		c.column.should == 0
		c.line.should == ""

		c.position += 1
		c.line_number.should == 3
		c.line_start.should == 2
		c.column.should == 0
		c.line.should == ""

		c.position -= 1
		c.line_number.should == 2
		c.line_start.should == 1
		c.column.should == 0
		c.line.should == ""
	end

#	it "should not move position behind backtrack border" do
#		c = Grammy::ParseContext.new(nil,nil,"line1\nline2\nline3\nline4\n")
#
#		c.position += 6
#		c.line_number.should == 2
#		c.line_start.should == 6
#		c.column.should == 0
#		c.line.should == "line2"
#
#		c.set_backtrack_border!
#
#		expect{ c.position -= 1 }.to raise_error
#
#		c.position += 8
#
#		expect{ c.position -= 9 }.to raise_error
#	end

end