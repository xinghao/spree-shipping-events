class ShipmentCommonFunction

  # sum the quantity if variant id is same
  def self.hash_sum(hash_a, hash_b)
    hash_b.each_pair do |key, value|
      if hash_a.include?(key)
        hash_a[key] += value
      else
        hash_a[key] = value 
      end
    end
    return hash_a;
  end
  
  # return data range hash {"start_from" => , end_at => }
  # default will be nil to today
  def self.get_date_range(start_from_str, end_at_str)
    date_range = Hash.new
    start_from = nil
    end_at = nil
    
    if !start_from_str.blank?
      begin
       date_range["start_from"] = DateTime.strptime(start_from_str, '%Y-%m-%d').to_time
      rescue
       date_range["start_from"] = nil
      end
    end
    
    if !end_at_str.blank?
      begin
       date_range["end_to"] = DateTime.strptime(end_at_str, '%Y-%m-%d').to_time + 1.day
      rescue
       date_range["end_to"] = nil
      end
    else
      date_range["end_to"] = DateTime.strptime(Date.today.to_s, '%Y-%m-%d').to_time
    end
    
    return date_range    
  end
  
  def self.build_shipment_data(start_from_str, end_at_str, preview)
    shipment_data = Hash.new
    shipment_data = {"start_from" => nil, "end_to" => nil, "display_hash" => nil, "total_send_products" => 0, "product_overview" => nil}

    date_range = ShipmentCommonFunction::get_date_range(start_from_str, end_at_str)
    shipment_data["start_from"] = date_range["start_from"]
    shipment_data["end_to"] = date_range["end_to"]        
    shipment_data["display_hash"] = ShipmentPreviewObject.build_display_data(shipment_data["start_from"], shipment_data["end_to"])
    
    if preview
      shipment_data["product_overview"] = Hash.new
      shipment_data["display_hash"].each_pair do |order_id,value|
        order = value["order"]
        shipment_data["total_send_products"] += order.inventory_units.where("state = ?", "sold").count
        shipment_data["product_overview"] = hash_sum(shipment_data["product_overview"], value["preview_object"].get_categorized_inventory["sold"])
      end        
    end
        
    return shipment_data    
  end
  
  
  def self.string_to_boolean(str)
    if str.downcase != "true" && str.downcase != "false"
      raise "unknow input for #{str}"
    end
    
    if str.downcase == "true"
      return true
    else
      return false
    end     
  end
end