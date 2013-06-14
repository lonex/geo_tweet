module TweetHelper
  
  def raw_tweet_to_tweet status
    id = status.id
    longitude = status.geo.coordinates[1].to_f
    latitude = status.geo.coordinates[0].to_f
    author = status.user
    user = author.screen_name
    profile_image_url = author.profile_image_url
    created_at = status.created_at
    ::Tweet.new(native_id: id, text: status.text, coordinates: [longitude, latitude], 
                   user: user, profile_image_url: profile_image_url, created_at: created_at)
  end
    
end