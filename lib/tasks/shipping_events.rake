namespace :shipping_events do
  
    desc "valid shipping events for a single order"
    task "se_create_valid", [:order_number] => [:environment] do |t, args|
      order_number = args[:order_number]
      order = Spree::Order.find_by_number order_number
      if order.nil?
        puts "Order not exist for #{order_number}" 
        return 
      end
      
      if order.shipments.size > 1
        puts "Order not exist for #{order_number}"
      end

      puts "#{order_number}: " + order.valid_shipping_events      
      
    end
    
    desc "create shipping events for a single order"
    task "se_create", [:order_number] => [:environment] do |t, args|
      order_number = args[:order_number]
      order = Spree::Order.find_by_number order_number
      if order.nil?
        puts "Order not exist for #{order_number}" 
        return 
      end
      
      if order.shipments.size > 1
        puts "Order not exist for #{order_number}"
      end

      
      puts "#{order_number}: " + order.valid_shipping_events
      order.create_shipments_shipping_events
      puts "Done...."      
      
    end
    
    
    desc "valid shipping events for all oders"
    task "scan_se_valid", [:amount] => [:environment] do |t, args|
      amount = args[:amount]
      amount = 0 if amount.blank?
      Spree::Order.fix_shipping_events(true, amount.to_i)            
    end
    
    desc "valid shipping events for all oders"
    task "scan_se", [:amount] => [:environment] do |t, args|
      amount = args[:amount]
      amount = 0 if amount.blank?
      Spree::Order.fix_shipping_events(false, amount.to_i)            
    end
    
end
