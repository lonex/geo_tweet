class GeoLocation
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  attr_accessor :longitude, :latitude

  class UnitValidator < ActiveModel::Validator
    include GeoParam

    def validate record
      long = record.longitude
      lat =  record.latitude
      unless UNIT_FORMAT =~ long and UNIT_FORMAT =~ lat
        record.errors[:coordinates] << ERR_MSG
      else
        unless valid_geo_coordinates?(long.to_f, lat.to_f)
          record.errors[:coordinates] << ERR_MSG
        end
      end
    end
  end
  
  validates_with UnitValidator
  
  def initialize long, lat
    @longitude = long
    @latitude = lat
  end
  
  def persisted?
    false
  end

  def saved?
    @saved ||= false
  end
  
  
end
