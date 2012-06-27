Spree::InventoryUnit.class_eval do
  
  
    # Assigns inventory to a newly completed order.
    # Should only be called once during the life-cycle of an order, on transition to completed.
    #
    def self.assign_opening_inventory(order)
      return [] unless order.completed?
      
      #increase inventory to meet initial requirements
      order.line_items.each do |line_item|
        increase(order, line_item.variant, line_item.quantity)
      end
      
      begin
        order.create_shipments_shipping_events()
      rescue Exception => e 
        Rails.logger.error("reassign_units error: " + e.message);
      end
    end
  # 
  # 
  # #same method as in shippment_controller  
  # def self.build_shipment(order)
  #   shipment = order.shipments.build
  #   shipment.address ||= order.ship_address
  #   shipment.address ||= Spree::Address.new(:country_id => Spree::Config[:default_country_id])
  #   shipment.shipping_method ||= order.shipping_method
  #   return shipment
  # end
  # 
  # 
  # def self.reassign_units(order)
  #   Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0: ")
  #   # units = order.inventory_units
  #   # Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF1: " + units.to_s)
  #   # backorder = order.backordered_inverntory_units_count;
  #   # return if backorder == 0
  #   # 
  #   # sold = order.sold_inverntory_units_count;
  #   # return if sold == 0 && backorder == 1
  #   # 
  #   # if sold == 0
  #   #   skip_first = true
  #   # else
  #   #   skip_first = false
  #   # end
  #   # icount = 0;
  #   # order.inventory_units.backorder.each do |unit|
  #   #   if icount > 0 || !skip_first       
  #   #     shipment = build_shipment(order)
  #   #     shipment.cost = 0;        
  #   #     shipment.inventory_unit_ids = Array.new.push(unit.id) 
  #   #     shipment.save
  #   #   end
  #   #   icount += 1; 
  #   # end    
  # 
  #   backorder = order.backordered_inverntory_units_count;
  #   sold = order.sold_inverntory_units_count;
  #   
  #   shipment = order.shipments.detect { |shipment| !shipment.shipped? }    
  #   ShippingEvent.create(:shipment => shipment,              
  #                         )
  #   Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF1: " + icount.to_s)
  # end

#     def self.create_units(order, variant, sold, back_order)
#       Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF1: " + back_order.to_s)
#       return if back_order > 0 && !Spree::Config[:allow_backorders]
# # Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF2: " + back_order.to_s)
# #       shipment = order.shipments.detect { |shipment| !shipment.shipped? }
# # Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF3: " + back_order.to_s)
# 
#       if back_order > 0 && sold > 0
#         Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF2: " + back_order.to_s)
#         shipment = order.shipments.detect { |shipment| !shipment.shipped? && !shipment.has_backorder_unit? }
#         if shipment.nil?
#           Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF3: " + back_order.to_s)
#           shipment = Spree::Shipment.create!(:order => order,
#                                             :shipping_method => order.shipping_method,
#                                             :address => order.ship_address)                    
#         end
# 
#         shipment_backorder = Spree::Shipment.create!(:order => order,
#                                           :shipping_method => order.shipping_method,
#                                           :address => order.ship_address)
#       elsif back_order == 0
#         Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF4: " + order.shipments.first.inventory_units.size.to_s)
#         Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF4.1: " + order.shipments.first.inventory_units.first.state.to_s)
#         shipment = order.shipments.detect { |shipment| !shipment.shipped? && !shipment.has_backorder_unit? }
#         if shipment.nil?
#           Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5: " + back_order.to_s)
#           shipment = Spree::Shipment.create!(:order => order,
#                                             :shipping_method => order.shipping_method,
#                                             :address => order.ship_address)                    
#         end
#       else
#         shipment_backorder = order.shipments.detect { |shipment| !shipment.shipped? && shipment.empty_inventory? }
#         Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF6: " + back_order.to_s)
#         if shipment_backorder.nil?
#           Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7: " + back_order.to_s)
#           shipment_backorder = Spree::Shipment.create!(:order => order,
#                                             :shipping_method => order.shipping_method,
#                                             :address => order.ship_address)                                                                                   
#         end
#         shipment = shipment_backorder
#       end
# 
#       # if back_order > 0
#       #   if sold == 0 
#       #     Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF4: " + back_order.to_s)
#       #     shipment_backorder = shipment
#       #   else
#       #     Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5: " + back_order.to_s)
#       #     shipment_backorder = Spree::Shipment.create!(:order => order,
#       #                                       :shipping_method => order.shipping_method,
#       #                                       :address => order.ship_address)          
#       #   end        
#       # end
#       Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8: " + sold.to_s)
#       sold.times { order.inventory_units.create(:variant => variant, :state => 'sold', :shipment => shipment) }
#       Rails.logger.info("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF9: " + back_order.to_s)
#       back_order.times { order.inventory_units.create(:variant => variant, :state => 'backordered', :shipment => shipment_backorder) }
#     end


end




# FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF1: 1
# FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF2: 1
#   Spree::Shipment Load (0.4ms)  SELECT "spree_shipments".* FROM "spree_shipments" WHERE "spree_shipments"."order_id" = 420
# FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF3: 1
# FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF4: 1
# FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF6: 0
# FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7: 1
#   SQL (0.8ms)  INSERT INTO "spree_inventory_units" ("created_at", "lock_version", "order_id", "return_authorization_id", "shipment_id", "state", "updated_at", "variant_id") VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8) RETURNING "id"  [["created_at", Fri, 22 Jun 2012 13:45:52 UTC +00:00], ["lock_version", 0], ["order_id", 420], ["return_authorization_id", nil], ["shipment_id", 82], ["state", "backordered"], ["updated_at", Fri, 22 Jun 2012 13:45:52 UTC +00:00], ["variant_id", 3]]
#    (0.4ms)  UPDATE "spree_variants" SET "count_on_hand" = 991 WHERE "spree_variants"."id" = 2
# FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF1: 0
# FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF2: 0
# FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF3: 0
# FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF6: 1
#   SQL (0.5ms)  INSERT INTO "spree_inventory_units" ("created_at", "lock_version", "order_id", "return_authorization_id", "shipment_id", "state", "updated_at", "variant_id") VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8) RETURNING "id"  [["created_at", Fri, 22 Jun 2012 13:45:52 UTC +00:00], ["lock_version", 0], ["order_id", 420], ["return_authorization_id", nil], ["shipment_id", 82], ["state", "sold"], ["updated_at", Fri, 22 Jun 2012 13:45:52 UTC +00:00], ["variant_id", 2]]
# FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7: 0
