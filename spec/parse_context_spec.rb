
require 'spec/spec_helper'

describe Grammy::ParseContext do

	it "should initialize context" do
		c = Grammy::ParseContext.new(nil,nil,"line1\nline2\n\n   line4")

		c.should have_properties(
			:position => 0,
			:line_number => 1,
			:line_start => 0,
			:column => 0,
			:line => 'line1'
		)
	end
	
	it "should keep line number when moving position inside line" do
		c = Grammy::ParseContext.new(nil,nil,"line1\nline2\n\n   line4")

		c.position += 2

		c.should have_properties(
			:position => 2,
			:line_number => 1,
			:line_start => 0,
			:column => 2,
			:line => 'line1'
		)
	end

	it "should adjust line number when moving position to next line" do
		c = Grammy::ParseContext.new(nil,nil,"line1\nline2\n\n   line4")

		c.position += 6

		c.should have_properties(
			:position => 6,
			:line_number => 2,
			:line_start => 6,
			:column => 0,
			:line => 'line2'
		)
	end

	it "should adjust line number when moving position back to previous line" do
		c = Grammy::ParseContext.new(nil,nil,"line1\nline2\n\n   line4")

		c.position += 6

		c.should have_properties(
			:position => 6,
			:line_number => 2,
			:line_start => 6,
			:column => 0,
			:line => 'line2'
		)

		c.position -= 2
		
		c.should have_properties(
			:position => 4,
			:line_number => 1,
			:line_start => 0,
			:column => 4,
			:line => 'line1'
		)
	end

	it "should adjust line number when moving position back to start of stream" do
		c = Grammy::ParseContext.new(nil,nil,"line1\nline2\n\n   line4")

		c.position += 12

		c.should have_properties(
			:position => 12,
			:line_number => 3,
			:line_start => 12,
			:column => 0,
			:line => ''
		)

		c.position -= 12

		c.should have_properties(
			:position => 0,
			:line_number => 1,
			:line_start => 0,
			:column => 0,
			:line => 'line1'
		)
	end

	it "should adjust line number when moving position to end of stream" do
		c = Grammy::ParseContext.new(nil,nil,"\n\n\n\n")

		c.position += 3

		c.should have_properties(
			:position => 3,
			:line_number => 4,
			:line_start => 3,
			:column => 0,
			:line => ''
		)
	end

	it "should adjust line number when moving position between empty lines" do
		c = Grammy::ParseContext.new(nil,nil,"\n\n\n\n")

		c.position += 1

		c.should have_properties(
			:position => 1,
			:line_number => 2,
			:line_start => 1,
			:column => 0,
			:line => ''
		)

		c.position += 1

		c.should have_properties(
			:position => 2,
			:line_number => 3,
			:line_start => 2,
			:column => 0,
			:line => ''
		)

		c.position -= 1

		c.should have_properties(
			:position => 1,
			:line_number => 2,
			:line_start => 1,
			:column => 0,
			:line => ''
		)
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