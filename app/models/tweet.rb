class Tweet
  include Mongoid::Document
  include GeoParam
  
  field :native_id, type: String
  field :text, type: String
  field :coordinates, type: Array
  index({coordinates: '2d'}, { background: true})

  field :created_at, type: DateTime
  field :user, type: String
  field :profile_image_url, type: String
  
  validates_presence_of :native_id, :allow_nil => false
  validate :valid_coordinates
  
  def valid_coordinates
    unless self.coordinates.nil?
      long = self.coordinates[0]
      lat  = self.coordinates[1]
      
      unless valid_geo_coordinates?(long, lat)
        errors.add(:coordinates, ERR_MSG)
      end
    end
  end
  
  def permalink
    "https://twitter.com/#!/%s" % user
  end
 
  def tweet_permalink 
    "https://twitter.com/%s/status/%s" % [user, native_id]
  end
  
end
