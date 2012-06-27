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
end
