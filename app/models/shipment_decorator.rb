Spree::Shipment.class_eval do

  has_many :shipping_events, :class_name => "ShippingEvent"
  accepts_nested_attributes_for :shipping_events
      
  def sold_inverntory_units_count
    count = 0;
    self.inventory_units.each do |unit|
      count += 1 if unit.state = 'sold'
    end
    return count;
  end

  def backordered_inverntory_units_count
    count = 0;
    self.inventory_units.each do |unit|
      count += 1 if unit.state = 'backordered'
    end
    return count;
  end

  def send_shipment_mail
    Spree::ShipmentMailer.shipped_email(self).deliver
  end
  
  def partial_shipped?
    return self.shipping_events.shipped.present?
  end
  
  def all_shipped?
    return true if (self.shipping_events.count == self.shipping_events.shipped.count)
    return false
  end
  
  def group_sold_inventory_units
    retHash = Hash.new
    self.shipping_events.un_shipped.each do |event|
      event.inventory_units.each do |unit|
        if (unit.state == "sold")
          if retHash.has_key?(unit.variant_id)
            retHash[unit.variant_id]["quantity"] += 1
          else
            retHash[unit.variant_id] = {"quantity" => 1};
          end
        end
      end       
    end
    return retHash
  end
  
  # group the sold items from different shpping events 
  def group_shipped_inventory_units
    retHash = Hash.new
    self.shipping_events.each do |event|
      if event.is_shipped?
        if retHash.has_key?(event.tracking)
          tmp = retHash[event.tracking]["units"]
          event.inventory_units.each do |unit|
            if (tmp.has_key?(unit.variant_id))
              tmp[unit.variant_id]["quantity"] += 1
            else
              tmp[unit.variant_id] = {"quantity" => 1, "sku" => unit.variant.sku, "name" => unit.variant.name};
            end
          end
        else
          tmp = Hash.new
          event.inventory_units.each do |unit|
            if (tmp.has_key?(unit.variant_id))
              tmp[unit.variant_id]["quantity"] += 1
            else
              tmp[unit.variant_id] = {"quantity" => 1, "sku" => unit.variant.sku, "name" => unit.variant.name};
            end            
          end
          retHash[event.tracking] = {"tracking" => event.tracking, "shipped_at" => event.shipped_at, "units" => tmp}
        end
      end
    end  
    return retHash;
  end

  
  # group the backordered items
  def group_backordered_inventory_units
    retHash = Hash.new
    self.inventory_units.backorder.each do |unit|
      if retHash.has_key?(unit.variant_id)
        retHash[unit.variant_id]["quantity"] += 1
      else
        retHash[unit.variant_id] = {"quantity" => 1, "sku" => unit.variant.sku, "name" => unit.variant.name};
      end 
    end
    return retHash;
  end
  
  def create_shipping_events()
    # sold = sold_inverntory_units_count;
    # backordered = backordered_inverntory_units_count;
    
    shipping_events.delete_all
    
    #se_sold = ShippingEvent.new
    sold_collections = Array.new;
    
    self.inventory_units.each do |unit|
      if (unit.state == 'sold')
        #sold_collections.push(InventoryShippingEvent.build(unit))
        sold_collections.push(unit)
      elsif (unit.state == 'backordered')
        se_backordered = ShippingEvent.new
        se_backordered.shipment = self
        #se_backordered.inventory_units = Array.new.push(InventoryShippingEvent.build(unit))
        se_backordered.inventory_units = Array.new.push(unit)
        se_backordered.save        
      end
    end
    
    if (sold_collections.size > 0)
        se_sold = ShippingEvent.new
        se_sold.shipment = self
        se_sold.inventory_units = sold_collections
        se_sold.save              
    end
    
  end
  
  def shipment_statement
    if (self.all_shipped?)
      return "shipped"
    else
      return "partially shipped"
    end
  end
    
  # def valid_address()
  #   return true if self.address_id == self.order.ship_address_id
  #   return true 
  # end
    
  # doing nothing after shipping
  def after_ship    
    # ShipmentMailer.shipped_email(self).deliver
  end
  
    # backorder = order.backordered_inverntory_units_count;
    # return if backorder == 0
    # 
    # sold = order.sold_inverntory_units_count;
    # return if sold == 0 && backorder == 1
    # 
    # if sold == 0
    #   skip_first = true
    # else
    #   skip_first = false
    # end
    # icount = 0;
    # order.inventory_units.backorder.each do |unit|
    #   if icount > 0 || !skip_first       
    #     shipment = build_shipment(order)
    #     shipment.cost = 0;        
    #     shipment.inventory_unit_ids = Array.new.push(unit.id) 
    #     shipment.save
    #   end
    #   icount += 1; 
    # end    
  
    # Updates various aspects of the Shipment while bypassing any callbacks.  Note that this method takes an explicit reference to the
    # Order object.  This is necessary because the association actually has a stale (and unsaved) copy of the Order and so it will not
    # yield the correct results.
    # def update!(order)
    #   
    #   old_state = self.state
    #   Rails.logger.info("1RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR1:" + old_state)
    #   new_state = determine_state(order)
    #   Rails.logger.info("1RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR2:" + new_state)
    #   update_attribute_without_callbacks 'state', determine_state(order)
    #   after_ship if new_state == 'shipped' and old_state != 'shipped'
    # end

  
  
    
end
