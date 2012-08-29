Spree::Variant.class_eval do
  
  # check how many 
  def valid_backorder()
    valid = true
    total = 0;
    total_previus_release = 0
    o = Spree::Order.find_by_number 'R748506805'
    Spree::InventoryUnit.includes(:order, :shipping_events).where("variant_id = ? and state = ?", self.id, "sold").order("id asc").find_each(:batch_size => 100) do |iu|
      if iu.order.completed_at <= o.completed_at
        total_previus_release += 1
        next 
      end

      total += 1;            
      if iu.order.state != "complete"
        puts "#{iu.order.number}  order state is wrong"
        valid = false
      end 
        
      if iu.order.shipment_state == 'shipped'
        puts "#{iu.order.number}  order shipment_state state is wrong"
        valid = false
      end 
      if iu.order.shipment.state == 'shipped'
        puts "#{iu.order.number} - #{iu.order.shipment.number} shipment state is wrong"
        valid = false 
      end
      iu.shipping_events.each do |se|
        if !se.tracking.blank?
          puts "#{iu.order.number} - #{se.number} state is wrong"
          valid =false 
        end 
      end      
    end    
    puts "Validated total: #{total}, before release #{total_previus_release}"
    return valid
  end
  
  
  
  def backorder(escape_account)
    o = Spree::Order.find_by_number 'R748506805'
    total_count = 0;
    total_previus_release = 0;
    total_processed = 0
    Spree::InventoryUnit.includes(:order, :shipping_events).where("variant_id = ? and state = ?", self.id, "sold").order("id asc").find_each(:batch_size => 100) do |iu|
      if iu.order.completed_at <= o.completed_at
        total_previus_release += 1
        next 
      end
      total_count += 1;
      puts total_count.to_s + " " + iu.order.number
      next if total_count <= escape_account      
      iu.state = "backordered"
      iu.save
      order = iu.order
      order.shipment.state = "pending"
      order.shipment.save
      order.shipment_state = 'backorder'
      order.save
      raise "#{order.number} state is wrong" if order.shipment_state != 'backorder'
      total_processed += 1 
    end    
    puts "Process total: #{total_count}, processed #{total_processed}, before release #{total_previus_release}"
  end
  
end
