namespace :shipment do
  namespace :output do
    namespace :exalt do
      desc "valid mark all the orders as processing in warehouse"
      task "mark_csv_valid", [:manifest_id, :limit] => [:environment] do |t, args|
          manifest_id = args[:manifest_id]
          limit = args[:limit]
          limit = 0 if limit.blank?
          exalt = ShipInfo::Exalt.new
          exalt.mark_order(manifest_id, limit, true, nil)          
      end
      
      desc "mark all the orders as processing in warehouse"
      task "mark_csv_url", [:url, :limit] => [:environment] do |t, args|
          url = args[:url]
          limit = args[:limit]
          limit = 0 if limit.blank?
          exalt = ShipInfo::Exalt.new
          exalt.mark_order(nil, limit, false, url)          
      end
      

      desc "valid mark all the orders as processing in warehouse"
      task "mark_csv_url_valid", [:url, :limit] => [:environment] do |t, args|
          url = args[:url]
          limit = args[:limit]
          limit = 0 if limit.blank?
          exalt = ShipInfo::Exalt.new
          exalt.mark_order(nil, limit, true, url)          
      end
      
      desc "mark all the orders as processing in warehouse"
      task "mark_csv", [:manifest_id, :limit] => [:environment] do |t, args|
          manifest_id = args[:manifest_id]
          limit = args[:limit]
          limit = 0 if limit.blank?
          exalt = ShipInfo::Exalt.new
          exalt.mark_order(manifest_id, limit, false, nil)          
      end
      
      desc "preview all current unshipped orders"
      task "preview_csv", [:start_from, :end_at] => [:environment] do |t, args|
        exalt = ShipInfo::Exalt.new
        preview_date = exalt.preview_to_csv(args[:start_from], args[:end_at])
        
        if preview_date["start_from"].nil?
          puts "From: " +  preview_date["start_from"].to_s
        else
          puts "From: Beginning"
        end
        
        puts "End: " +  preview_date["end_to"].to_s
                
        # puts "Total Order involved: " + preview_date["display_hash"].size.to_s
        # puts "Total Products needs to be send: " + preview_date["total_send_products"].to_s
        # 
        # puts "Quantity  -  Product Name"
        # preview_date["product_overview"].each_pair do |key, value|
        #   puts "#{value.to_s}  -  #{Spree::Variant.find(key).name_with_options_text}"
        # end
        
      end
      
      desc "export all current unshipped orders"
      task "export_csv", [:start_from, :end_at] => [:environment] do |t, args|
        exalt = ShipInfo::Exalt.new
        puts exalt.export_to_csv(args[:start_from], args[:end_at])
      end                        
                              
    end
  end
    
  namespace :input do
    namespace :exalt do
      desc "check bbq warehouse states entries in manifest"
      task "whs_in_manifest", [:manifest_id] => [:environment] do |t, args|
        manifest_id = args[:manifest_id]
        manifest_entries = ShipInfo::Exalt.make_manifest_hash_hash(manifest_id)
        ews_entries = ExaltWarehouseState.make_hash_hash
        
        puts "Manifest entries: #{manifest_entries.size}"
        puts "BBQ Warehouse entries: #{ews_entries.size}"
        missing_count = 0
        ews_entries.each_pair do |key, id|
          puts "Id: #{id}, Hash: #{key}" if !manifest_entries.has_key?(key)
          missing_count += 1
        end
        
        puts "Total #{missing_count} entries missing" if missing_count > 0
      end
      
      
      desc "market manifest as processed"
      task "market_as_commit", [:manifest_id] => [:environment] do |t, args|
         manifest_id = args[:manifest_id]
         exalt = ShipInfo::Exalt.new
         exalt.commit_manifest(manifest_id)
      end
      
      desc "validate manifest, start from 1"
      task "validate", [:manifest_id, :start, :limit] => [:environment] do |t, args|
          manifest_id = args[:manifest_id]
          limit = args[:limit]
          start = args[:start]
          exalt = ShipInfo::Exalt.new
          exalt.process_manifext(manifest_id, false, start.to_i, limit.to_i, true, true)          
      end
      
      desc "process manifest, start from 1"
      task "process", [:skip_mail, :manifest_id, :start, :limit] => [:environment] do |t, args|
        
        skip_mail = ShipmentCommonFunction.string_to_boolean(args[:skip_mail])
        #only_send_to_backorder = ShipmentCommonFunction.string_to_boolean(args[:only_send_to_backorder])
        skip_mail = true if skip_mail == nil || (skip_mail != true && skip_mail != false)
        puts "======================Skip Email: #{skip_mail}"
        manifest_id = args[:manifest_id]
        limit = args[:limit]
        limit = 0 if limit.blank?
        start = args[:start]
        exalt = ShipInfo::Exalt.new
        exalt.process_manifext(manifest_id, skip_mail, start.to_i, limit.to_i, false, false)
                  
      end      
            
    end
  end  
    def process_leyats_csv_file(url, limit)
      total = 0;
      error = 0;
      skip = 0;
      processed = 0 ;
      CSV.new(open(url), :headers => :first_row).each do |row|
      #CSV.foreach("imports/" + file_name, :headers => true, :col_sep =>',', :row_sep =>:auto) do |row|
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
    
    def valid_leyats_csv_file(url, limit)
      total = 0;
      error = 0;
      skip = 0;
      processed = 0;
      warning = 0;
      CSV.new(open(url), :headers => :first_row).each do |row|
#      CSV.foreach("imports/" + file_name, :headers => true, :col_sep =>',', :row_sep =>:auto) do |row|
        break if !limit.nil? && !limit.empty? && total == limit.to_i        
        order_number = row["order number"].strip;
        email = row["email"].strip
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
          warning += 1;
          puts "Warning: #{order_number} user email does not match csv's email. #{order.user.email} != #{email}"
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
      
      puts "Total Valid: #{total.to_s}, error: #{error.to_s}, warning: #{warning.to_s}, skip: #{skip.to_s}, processed: #{processed.to_s}"
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
    
    desc "valid leyats 29.5-4.7 recent.csv, please upload to s3 first"
    task "valid_leyats_csv", [:url, :limit] => [:environment] do |t, args|
      url = args[:url]
      limit = args[:limit]
      valid_leyats_csv_file(url, limit)
    end
    
    desc "valid leyats 29.5-4.7 recent.csv, please upload to s3 first"
    task "process_leyats_csv", [:url, :limit] => [:environment] do |t, args|
      url = args[:url]
      limit = args[:limit]
      if valid_leyats_csv_file(url, limit)
        process_leyats_csv_file(url, limit)
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
