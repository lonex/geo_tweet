class GeoLocationsController < ApplicationController
  include GeoParam

  skip_before_filter :verify_authenticity_token  

  QUERY_PARAMS = HashWithIndifferentAccess.new(YAML::load_file(File.join(Rails.root, 'config', 'search_criteria.yml')))
  
  def index
  end

  def create
    Rails.logger.info "#{params.inspect}"
    @geo_location = GeoLocation.new(params[:geo_location][:longitude], params[:geo_location][:latitude])
    if @geo_location.valid?
      query @geo_location.longitude.to_f, @geo_location.latitude.to_f
      render :action => "index"
    else
      render :action => "search"
    end
  end
  
  def search
    @geo_location = GeoLocation.new(0,0)
  end
  
  def query longitude, latitude
    limit = QUERY_PARAMS[:limit]
    (@tweets = []).tap do
      QUERY_PARAMS[:radius].each do |radius|
        @tweets += find_tweets(longitude, latitude, radius)
        Rails.logger.info "FOUND #{@tweets.size} tweets..."
        break if @tweets.size >= limit
      end
    end
    
    @tweets = @tweets.first(limit)
    @tweets.each do |tw|
      Rails.logger.info "TW #{tw.inspect}"
    end
  end
  
  
  protected
  
  def find_tweets longitude, latitude, distance_in_km
    tweets = Tweet.desc(:created_at)
                  .limit(QUERY_PARAMS[:limit])
                  .where(:coordinates => 
                    {
                      NEAR => [longitude, latitude], MAX_DISTANCE => distance_in_geo_degree(distance_in_km) 
                    }
                  )
  end
  
end
