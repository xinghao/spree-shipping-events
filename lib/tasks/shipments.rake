namespace :shipment do
  
    def process_leyats_csv_file(file_name, limit)
      total = 0;
      error = 0;
      skip = 0;
      processed = 0 ;
      CSV.foreach("imports/" + file_name, :headers => true, :col_sep =>',', :row_sep =>:auto) do |row|
        break if !limit.nil? && !limit.empty? && total == limit.to_i          
        order_number = row["order number"];
        email = row["email"]
        track_number = row["Tracking number "]
        total += 1;
        if track_number.blank?
          skip += 1
          next
        end                 
        order = Spree::Order.includes(:user, :shipments).find_by_number order_number
        shipment = order.shipments.first
        if (!shipment.tracking.blank?)
          processed += 1;
          next
        end
        shipment.inventory_units.each &:ship!
        
        shipment.shipping_events.each do |se|
          se.tracking = track_number;
          se.shipped_at = Time.now
          se.save
        end
        
        shipment.tracking = track_number;        
        shipment.state = "shipped"
        shipment.shipped_at = Time.now
        shipment.save
        shipment.update!(order)
        shipment.order.shipment_state = shipment.state
        shipment.order.save 
      end
      
      puts "Total processed: #{total.to_s}, error: #{error.to_s}, skip: #{skip.to_s}, processed: #{processed.to_s}"
      if error == 0
        return true
      else
        return false
      end      
    end
    
    # def check_after_process_leyats_csv_file(file_name, limit)
    #   total = 0;
    #   error = 0;
    #   skip = 0;
    #   CSV.foreach("imports/" + file_name, :headers => true, :col_sep =>',', :row_sep =>:auto) do |row|        
    #     order_number = row["order number"];
    #     email = row["email"]
    #     track_number = row["Tracking number"]
    #     total += 1;
    #     if track_number.blank?
    #       skip += 1
    #       next
    #     end         
    #     order = Spree::Order.includes(:user, :shipments).find_by_number order_number
    #     if (order)
    #     break if !limit.nil? && !limit.empty? && total == limit.to_i   
    #   end
    #   
    #   puts "Total checked: #{total.to_s}, error: #{error.to_s}, skip: #{skip.to_s}"
    #   if error == 0
    #     return true
    #   else
    #     return false
    #   end            
    # end
    
    def valid_leyats_csv_file(file_name, limit)
      total = 0;
      error = 0;
      skip = 0;
      processed = 0;
      CSV.foreach("imports/" + file_name, :headers => true, :col_sep =>',', :row_sep =>:auto) do |row|
        break if !limit.nil? && !limit.empty? && total == limit.to_i        
        order_number = row["order number"];
        email = row["email"]
        track_number = row["Tracking number "]
        puts "order: #{order_number}, email: #{email}, tracking: #{track_number}"
        total += 1;
        if track_number.blank?
          skip += 1
          next
        end 
        order = Spree::Order.includes(:user, :shipments).find_by_number order_number
        if order.blank?
          error += 1;
          puts "ERROR: #{order_number} does not exist!" 
          next
        end
        
        if order.user.email != email
          error += 1;
          puts "ERROR: #{order_number} user email does not match csv's email. #{order.user.email} != #{email}"
         next
        end
        
        if !order.shipments.first.tracking.nil? &&  !(order.shipments.first.tracking == track_number || order.shipments.first.tracking.include?(track_number)) 
          error += 1;
          puts "ERROR: #{order_number} tracking number does not match csv's tracking number"
        elsif !order.shipments.first.tracking.nil? 
          valid_state = true
          if (order.shipment_state != 'shipped' || order.shipments.first.state != 'shipped' || order.payment_state != 'paid')
            valid_state = false  
          end         
          
          if (valid_state)
            order.inventory_units.each do |iu|
              if iu.state != 'shipped'
                valid_state = false
                break
              end
            end
          end
          
          if (valid_state)
            order.shipments.first.shipping_events.each do |se|
              if !se.is_shipped?
                valid_state = false
                break                
              end
            end
          end
          
          if (valid_state)
            processed += 1;            
          else
            error += 1;            
            puts "ERROR: #{order_number} has wrong state!"
          end
        end
                
      end
      
      puts "Total Valid: #{total.to_s}, error: #{error.to_s}, skip: #{skip.to_s}, processed: #{processed.to_s}"
      if error == 0
        return true
      else
        return false
      end
    end
    
    desc "output shipments to csv"
    task "output_to_csv" => :environment do
      ShippingEvent.output_csv("file.csv")
    end
    
    desc "valid leyats 29.5-4.7 recent.csv"
    task "valid_leyats_csv", [:file_name, :limit] => [:environment] do |t, args|
      file_name = args[:file_name]
      limit = args[:limit]
      valid_leyats_csv_file(file_name, limit)
    end
    
    desc "valid leyats 29.5-4.7 recent.csv"
    task "process_leyats_csv", [:file_name, :limit] => [:environment] do |t, args|
      file_name = args[:file_name]
      limit = args[:limit]
      if valid_leyats_csv_file(file_name, limit)
        process_leyats_csv_file(file_name, limit)
#        valid_leyats_csv_file(file_name, limit)
      end
      
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
