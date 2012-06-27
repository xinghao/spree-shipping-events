namespace :shipment do
    desc "output shipments to csv"
    task "output_to_csv" => :environment do
      ShippingEvent.output_csv("file.csv")
    end
    
    desc "stat the completed orders"
    task "stats" => :environment do
      complete_paid = 0
      complete_balance = 0
      complete_others = 0
      
      total_shipping_events = ShippingEvent.un_shipped.count
      
      Spree::Order.where("state = 'complete' and payment_state = 'paid'").all.each do |order|
        order.shipments.each do |shipment|
          shipment.shipping_events.each do |se|
            complete_paid += 1 if !se.is_shipped?
          end
        end        
      end
      
      Spree::Order.where("state = 'complete' and payment_state = 'balance_due'").all.each do |order|
        order.shipments.each do |shipment|
          shipment.shipping_events.each do |se|
            complete_balance += 1 if !se.is_shipped?
          end
        end        
      end
      
      Spree::Order.where("state = 'complete' and payment_state != 'balance_due' and payment_state != 'paid' ").all.each do |order|
        order.shipments.each do |shipment|
          shipment.shipping_events.each do |se|
            complete_others += 1 if !se.is_shipped?
          end
        end        
      end
      
      
      # ShippingEvent.un_shipped.each do |ship_event|
      #   puts ship_event.number
      #   if ship_event.shipment.order.payment_state = 'paid'
      #     complete_paid += 1
      #   elsif ship_event.shipment.order.payment_state = 'balance_due'
      #     complete_balance += 1
      #   else
      #     complete_others += 1
      #   end  
      # end
      puts "Shipping events total: " + total_shipping_events.to_s
      puts "Complete paid: " + complete_paid.to_s
      puts "Complete due: " + complete_balance.to_s
      puts "Complete others: " + complete_others.to_s
      
    end
end
