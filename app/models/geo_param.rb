module GeoParam
  
  NEAR ||= "$near"
  MAX_DISTANCE ||= "$maxDistance"
  LONGITUDE_MAX ||= 180
  LATITUDE_MAX ||= 90
  
  UNIT_FORMAT = /\A(\+|\-)?[\d.]+\z/
  
  ERR_MSG = "longitude and latitude must be valid."
  
  def valid_geo_coordinates? long, lat
    if long > LONGITUDE_MAX || long < -LONGITUDE_MAX || lat > LATITUDE_MAX || lat < -LATITUDE_MAX
      false
    else
      true
    end
  end
  
  def distance_in_geo_degree km
    km / 111.12
  end
  
end