class GeoLocation
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  attr_accessor :longitude, :latitude

  class UnitValidator < ActiveModel::Validator
    include GeoParam

    def validate record
      Rails.logger.info "___ record #{record.class}, #{record.inspect}"
      long = record.longitude
      lat =  record.latitude
      unless UNIT_FORMAT =~ long and UNIT_FORMAT =~ lat
        Rails.logger.info "000"
        record.errors[:coordinates] << ERR_MSG
      else
        Rails.logger.info "111"
        unless valid_geo_coordinates?(long.to_f, lat.to_f)
          Rails.logger.info "22"
          record.errors[:coordinates] << ERR_MSG
        else
          Rails.logger.info "--- Valid GeoLocation #{long}, #{lat}"
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
