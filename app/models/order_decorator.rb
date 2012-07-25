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
        state = order.ship_address.state_text
        postcode = order.ship_address.zipcode
        
        
        raise "We don't support mulitple shipments per order now!: " + order.number.to_s if order.shipments.count > 1
        s = order.shipments.first
        source1 = s.group_sold_inventory_units
        
        
        se_numbers = ""
        s.shipping_events.each do |se|
          if !se.is_shipped? && !se.has_backordered_inventory?
            if se_numbers.size > 0
              se_numbers += "," + se.number 
            else
              se_numbers += se.number
            end
          end  
        end
        
        inventory_ids = ""
        order.inventory_units.each do |unit|
          if unit.state == "sold"
            if inventory_ids.size > 0
              inventory_ids += "," + unit.id.to_s 
            else
              inventory_ids += unit.id.to_s
            end
          end            
        end
        
        pd = "[#{order.number}]:[#{se_numbers}]:[#{inventory_ids}]";
        raise "error in making [order][shipping_events][inventory_unit_ids]: " + pd if parse_pd_string(pd).nil?        
        # puts source1.size
        # puts value["preview_object"].get_categorized_inventory["sold"].size
         
        raise "validate products amount failed!:" + order.number + "[#{source1.size.to_s} =? #{value["preview_object"].get_categorized_inventory["sold"].size.to_s}]" if (source1.size != value["preview_object"].get_categorized_inventory["sold"].size)
        
        prduct_name_amount = ""
        total_weight = 0;
        value["preview_object"].get_categorized_inventory["sold"].each_pair do |variant_id, quantity|
          raise "validate product quantity failed!:" + order.number + ", prodcut: " + variant_id.to_s if (source1[variant_id]["quantity"] != quantity)
          v = Spree::Variant.find(variant_id)
          raise v.product.name + " does not have acutal weight!!" if v.product.actual_weight.nil? || v.product.actual_weight.to_f == 0
          total_weight += v.product.actual_weight.to_f * quantity;
          if prduct_name_amount.size > 0
            prduct_name_amount += "," + v.product.name + "(#{quantity})"
          else
            prduct_name_amount = v.product.name + "(#{quantity})"
          end
         # short_description = "[#{order.number}:#{variant_id}] - " + v.product.short_description.to_s.truncate(200)
        end 
        csv << ["C","","",contract_charge_code,"",name,"",address1,address2,address3,address4,suburb,state,postcode,"AU","","N","","",prduct_name_amount]
#          csv << ["A",p.weight,p.depth,p.width,p.height,quantity,p.short_description.to_s.truncate(250),"","","","","","","","N","N","N","N",""]
        csv << ["A",total_weight,"","","",1,pd,"","","","","","","","N","N","N","N",""]                    
                                         
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

  # return array of se numbers
  def self.parse_pd_string(pd)
    reg = /\[(.*)\]:\[(.*)\]:\[(.*)\]/
    md = reg.match pd
    return nil if md.size != 4
    
    order = Spree::Order.find_by_number md[1]
    return nil if order.nil?
    
    pd_ses = md[2].split(",")
    pd_inventory_ids = md[3].split(",")
    src_inventory_ids = Array.new
    hit_ses_count = 0
    order.shipments.first.shipping_events.each do |se|
      if pd_ses.include?(se.number)
        return nil if se.is_shipped?
        hit_ses_count += 1
        se.inventory_units.each do |unit|
          return nil if unit.state != 'sold'
          src_inventory_ids.push(unit.id.to_s)
        end
      end
    end
    
    return nil if hit_ses_count != pd_ses.size
    
    return nil if src_inventory_ids.size != pd_inventory_ids.size || (src_inventory_ids - pd_inventory_ids).size !=0
    
    return pd_ses;  
  end
  
  
  def bought?(variant_id)
    self.line_items.each do |line_item|
      return line_item.quantity if line_item.variant_id == variant_id        
    end
    
    return 0
  end
  
  
end