namespace :orders do
    desc "stat the completed orders"
    task "stats" => :environment do
      complete_total = Spree::Order.complete.count
      cancelled = Spree::Order.where("state = 'canceled'").count
      complete_paid = Spree::Order.where("state = 'complete' and payment_state = 'paid'").count
      complete_balance = Spree::Order.where("state = 'complete' and payment_state = 'balance_due'").count
      complete_others = Spree::Order.where("state = 'complete' and payment_state != 'balance_due' and payment_state != 'paid'").count
      puts "Cancelled: " + cancelled.to_s
      puts "Complete totally: " + complete_total.to_s
      puts "Complete paid: " + complete_paid.to_s
      puts "Complete due: " + complete_balance.to_s
      puts "Complete others: " + complete_others.to_s
      
    end
    
    desc "shipping fee fix for changing shipping rates"
    task "fix_shipping_fee_for_change_rate", [:adjustment_amount, :limit, :process] => [:environment] do |t, args|
      adjustment_amount = args[:adjustment_amount].to_f
      limit = args[:limit].to_i
      processed = 0;
      error = 0;
      if args[:process].downcase == "true"
        process = true
      else
        process = false
      end 
      
      puts "Adjustment_amount: #{adjustment_amount.to_s}, limit: #{limit.to_s}, process: #{process.to_s}"
       if adjustment_amount > 0
        payment_state = 'credit_owed'
      else
          payment_state = 'balance_due'
      end                 
      
      total = 0;
      Spree::Order.includes(:payments, :line_items).where("state = 'complete' and payment_state = ?", payment_state).order("completed_at asc").find_each(:batch_size => 500) do |order|
        next if order.outstanding_balance != 0 - adjustment_amount
        next if order.ship_total != 20 - adjustment_amount 
        puts "-Order: #{order.number}, Total: #{order.total.to_s}, Outstanding Balance:#{order.outstanding_balance.to_s}, Shipment: #{ship_total.to_s}"
        
       if (process)
            adjustment = Spree::Adjustment.new(:adjustable => order, :amount => adjustment_amount, :label => "Shipping fee adjustment scripts")
            
            adjustment.save      
            if (order.payment_state == 'paid')
              processed += 1
            else
              error += 1
              puts "ERROR in this #{order.number}"
            end
        end        
        
        total += 1;
        break if total >= limit 
      end           
      puts "Total: #{total.to_s}, Processed: #{processed.to_s}, Error: #{error.to_s}"
    end
    
    
    desc "shipping fee fix for change weight of a product"
    task "fix_shipping_fee_for_change_weight", [:variant_id, :adjustment_amount, :limit, :process] => [:environment] do |t, args|
      variant_id = args[:variant_id].to_i
      adjustment_amount = args[:adjustment_amount].to_f
      limit = args[:limit].to_i
      processed = 0;
      error = 0;
      if args[:process].downcase == "true"
        process = true
      else
        process = false
      end
      
      variant = Spree::Variant.find_by_id variant_id
      
      puts "Product: #{variant.name}, adjustment_amount: #{adjustment_amount.to_s}, limit: #{limit.to_s}, process: #{process.to_s}"
      
      if adjustment_amount > 0
        payment_state = 'credit_owed'
      else
          payment_state = 'balance_due'
      end                 
      
      total = 0;
      Spree::Order.includes(:payments, :line_items).where("state = 'complete' and payment_state = ?", payment_state).order("completed_at asc").find_each(:batch_size => 500) do |order|
        quantity = order.bought?(variant_id)
        next if quantity == 0
        #puts "Order: #{order.number},Outstanding Balance:#{order.outstanding_balance.to_s}"
        next if order.outstanding_balance != 0 - adjustment_amount
        puts "-Order: #{order.number}, Total: #{order.total.to_s}, Outstanding Balance:#{order.outstanding_balance.to_s}, Quantity: #{quantity}"
        
        if (process)
            adjustment = Spree::Adjustment.new(:adjustable => order, :amount => adjustment_amount, :label => "Shipping fee adjustment scripts")
            
            adjustment.save      
            if (order.payment_state == 'paid')
              processed += 1
            else
              error += 1
              puts "ERROR in this #{order.number}"
            end
        end        
        
        total += 1;
        break if total >= limit
      end
      
      puts "Total: #{total.to_s}, Processed: #{processed.to_s}, Error: #{error.to_s}"
    
    end
end
