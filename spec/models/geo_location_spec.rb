require 'spec_helper'

describe 'Geo location input' do
  
  it "['0', '0'] should be valid coordinates" do
    obj = GeoLocation.new("0", "0")
    obj.valid?.should be_true
  end

  it "['-179.001', '89.00'] should be valid coordinates" do
    obj = GeoLocation.new("-179.001", "89.00")
    obj.valid?.should be_true
  end

  it "['-180.01', '89.00'] should not be valid coordinates" do
    obj = GeoLocation.new("-180.01", "89.00")
    obj.valid?.should be_false
  end

  it "['xxx', '89.00'] should not be valid coordinates" do
    obj = GeoLocation.new("x", "89.00")
    obj.valid?.should be_false
  end


end