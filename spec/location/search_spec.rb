require 'spec_helper'

describe 'Tweet(s) for Geo location search' do
  
  include GeoParam
  
  before(:all) do
    # [ -1.1, 3.1 ]  [ -1.2, 3.1]
    [:a_tweet, :b_tweet, :geo_disabled_tweet].each do |t|
      instance_variable_set(:"@#{t}", FactoryGirl.create(t))
    end
    # 1 degree is about 111.12 km, 0.1 degree is about 11.112 degree
    @super_distance = 1000 # km
    @big_distance = 25 
    @long_enough_distance = 11.12
    @short_distance = 11.11
    @location = [-1.0, 3.1]
  end

  it "should find two tweets within the radius" do
    tws = Tweet.where(:coordinates => {GeoParam::NEAR => @location , GeoParam::MAX_DISTANCE => distance_in_geo_degree(@big_distance) })
    tws.size.should eq(2)
  end
  
  it "should find only one tweet within the radius" do
    tws = Tweet.where(:coordinates => {GeoParam::NEAR => @location , GeoParam::MAX_DISTANCE => distance_in_geo_degree(@long_enough_distance) })
    tws.size.should eq(1)
    tws.first.should eq(@a_tweet)
  end

  it "should not find the tweet outside of the radius" do
    tws = Tweet.where(:coordinates => {GeoParam::NEAR => @location , GeoParam::MAX_DISTANCE => distance_in_geo_degree(@short_distance) })
    tws.size.should eq(0)
  end
  
  it "should not include geo-disabled tweets"do
    tws = Tweet.where(:coordinates => {GeoParam::NEAR => @location , GeoParam::MAX_DISTANCE => distance_in_geo_degree(@super_distance) })
    tws.should_not include(@geo_disabled_tweet)
  end

  after(:all) do
    DatabaseCleaner.clean
  end
  
end