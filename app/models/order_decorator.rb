Spree::Order.class_eval do
  
  def create_shipments_shipping_events()    
    shipments.each do |shipment|
      if (shipment.state != 'shipped')     
        shipment.create_shipping_events   
      end
    end
  end
  
  
  def need_ship?
    inventory_units_amount = self.inventory_units.where("state = ?",'sold').count
    e_count = 0
    self.shipments.first.shipping_events.un_shipped.each do |se|
      se.inventory_units.each do |unit|
        e_count += 1 if unit.state == 'sold'
      end
    end
    raise "valid need ship failed: " + self.number if (inventory_units_amount != e_count)
    return true if inventory_units_amount > 0
    return false
  end
  
  def self.export_avaible_shipments_to_csv(display_hash)
    contract_charge_code = "S9"
    
    business_name = ""
    
    csv_string = CSV.generate do |csv|     

        
      display_hash.each_pair do |order_id, value|
        order = value["order"]
        #puts order.number
        name = order.ship_address.full_name        
        address1 = order.ship_address.address1
        address2 = order.ship_address.address2
        address3 = ""
        address4 = ""
        suburb = order.ship_address.city
        state = order.ship_address.state_name
        postcode = order.ship_address.zipcode
        
        
        raise "We don't support mulitple shipments per order now!: " + order.number.to_s if order.shipments.count > 1
        s = order.shipments.first
        source1 = s.group_sold_inventory_units
        
        # puts source1.size
        # puts value["preview_object"].get_categorized_inventory["sold"].size
         
        raise "validate products amount failed!:" + order.number + "[#{source1.size.to_s} =? #{value["preview_object"].get_categorized_inventory["sold"].size.to_s}]" if (source1.size != value["preview_object"].get_categorized_inventory["sold"].size)
        
        value["preview_object"].get_categorized_inventory["sold"].each_pair do |variant_id, quantity|
          raise "validate product quantity failed!:" + order.number + ", prodcut: " + variant_id.to_s if (source1[variant_id] == quantity)
          v = Spree::Variant.find(variant_id)
          short_description = "[#{order.number}:#{variant_id}] - " + v.product.short_description.to_s.truncate(200)
          csv << ["C","","",contract_charge_code,"",name,"",address1,address2,address3,address4,suburb,state,postcode,"AU","","N","","",v.name]
#          csv << ["A",p.weight,p.depth,p.width,p.height,quantity,p.short_description.to_s.truncate(250),"","","","","","","","N","N","N","N",""]
          csv << ["A","",v.depth,v.width,v.height,quantity,short_description,"","","","","","","","N","N","N","N",""]                    
        end 
                                         
      end
      
      
    end # end of csv_string
    return csv_string
  end  
  
  #{"sold"=>{{product_id1 => quantity},{product_id2 => quantity}}, "shipped" => {{product_id1 => quantity},{product_id2 => quantity}}, 
  # "returned" => {{product_id1 => quantity},{product_id2 => quantity}}, "backordered" => {{product_id1 => quantity},{product_id2 => quantity}}} 
  def group_inventory()
    retHash = Hash.new
    if validate_inventory()
      self.inventory_units.each do |unit|
        retHash[unit.state] = Hash.new if !retHash.has_key?(unit.state)
        if retHash[unit.state].has_key?(unit.variant_id)
          retHash[unit.state][unit.variant_id] += 1
        else
          retHash[unit.state][unit.variant_id] = 1
        end 
      end
    else
      return nil
    end
    
    return retHash
  end
  
  # only should be called after order is complete and ans inventory_units been assgined to shipment
  def validate_inventory()
    validated = true
    line_item_total = 0
    line_item_hash = Hash.new    
    self.line_items.each do |line_item|
      line_item_hash[line_item.variant_id] = line_item.quantity
      line_item_total += line_item.quantity
    end
    
    
    inventory_total = 0
    inventory_hash = Hash.new            
    self.inventory_units.each do |unit|
      inventory_total += 1
      if inventory_hash.has_key?(unit.variant_id)
        inventory_hash[unit.variant_id] += 1
      else
        inventory_hash[unit.variant_id] = 1
      end 
    end
    
    validated = false if (inventory_total != line_item_total)
    self.line_items.each do |line_item|
      validated = false  if line_item_hash[line_item.variant_id] != inventory_hash[line_item.variant_id]
      break if !validated 
    end
    
    raise "inventory_units not matched with line item: " + self.number if !validated


    shipping_events_total = 0
    shipping_events_hash = Hash.new
    self.shipments.first.shipping_events.each do |se|
      se.inventory_units.each do |unit|
        # puts se.id.to_s + "#" + unit.id.to_s
        # puts se.shipped_at
        # puts unit.state        
        shipping_events_total += 1
        if se.is_shipped?
           validated = false if unit.state != 'returned' && unit.state != 'shipped' 
        else
          validated = false if unit.state == 'shipped'
        end
        
        
         break if !validated 
      end
    end
    
    
    raise "inventory_units state not matched with shipping events: " + self.number if !validated
    
    validated = false if (inventory_total != shipping_events_total)
    # puts inventory_total
    # puts shipping_events_total
    raise "inventory_units total not matched with shipping events: " + self.number if !validated
    
    return validated    
    
  end
  
end