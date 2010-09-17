
require 'spec/spec_helper'

describe Hash do
	it "#only should return a hash" do
		hash = {a: 1, 2 => 5, 'c' => 'd'}
		hash.only(:a).should == {a: 1}
		hash.only(:a,2,'c').should == hash
		hash.only(:a,:b,'c',5,2).should == hash
		hash.only(:a,:a).should == {a: 1}
		hash.only(nil).should == {}
	end
	
	it "#slice should return an array of values" do
		hash = {a: 1, 2 => 5, 'c' => 'd'}
		hash.slice(2,:a,'c').should == [5,1,'d']
		hash.slice(2,2).should == [5,5]
		hash.slice(:gth,'c ',2).should == [5]
		hash.slice(nil).should == []
	end
	
	it "#except"
	it "#extract"
	it "#with_default should fill in default values"
	it "#map_keys"
	
	it "#symbolize_keys should raise if not symbolizeable" do
		expect{
			{a: 1, 2 => 5, 'c' => 'd'}.symbolize_keys
		}.to raise_error(NoMethodError)
	end
	
	it "#symbolize_keys" do
		hash = {a: 1, 'test' => 5, '1' => 'd'}
		hash.symbolize_keys.should == {a: 1, test: 5, :'1' => 'd'}
	end
end
