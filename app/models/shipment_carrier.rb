class ShipmentCarrier < ActiveRecord::Base
  DEFAULT_CARRIER = "* Auto Selection *"
  
  
  def self.get_carrier(carrier_name)
    if carrier_name.blank?
      return nil
    else
      return ShipmentCarrier.find_by_name carrier_name
    end
  end
  
  def self.get_query_url(carrier_name)
    return nil if carrier_name.blank?
    carrier = ShipmentCarrier.find_by_name carrier_name
    if carrier.nil?
      return nil
    else
      return carrier.query_url
    end
  end
end
