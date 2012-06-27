class ShipmentPreviewObject
  # @order_number = nil
  # @order_completed_at = nil
  # @order_payment_state = nil
  # @sold_inventory_units = nil
  # @shipped_inventory_units = nil
  # @backordered_inventory_units = nil
  # @return_inventory_units = nil
  @categorized_inventory = nil
  @total_products = 0
  
  def initialize
    @categorized_inventory = Hash.new
    @total_products = 0
  end

  
  def self.build_display_data
    orders = Spree::Order.includes(:ship_address).where("state = 'complete' and payment_state = 'paid'").order("completed_at asc").all
    display_hash = Hash.new
    
    orders.each do |order|
      if order.shipments.first.shipping_events.present? && !order.shipments.first.all_shipped?
        display_hash[order.id] = {"preview_object" => ShipmentPreviewObject.build_from_order(order), "order" => order}
        #total_send_products += order.inventory_units.where("state = ?", "sold").count
      end 
    end 
    
    return display_hash 
  end
      
  def get_categorized_inventory
    return @categorized_inventory
  end
  
  def category_count()
    return 0 if @categorized_inventory.nil?
    return @categorized_inventory.size
    # count = 0
    # count += 1 if @sold_inventory_units.nil? && @sold_inventory_units.size > 0
    # count += 1 if @shipped_inventory_units.nil? && @shipped_inventory_units.size > 0
    # count += 1 if @backordered_inventory_units.nil? && @backordered_inventory_units.size > 0
    # count += 1 if @return_inventory_units.nil? && @return_inventory_units.size > 0
    # 
    # return count
  end
  
  def self.build_from_order(order)
    raise "can not do with mulitple shippments in one order" if order.shipments.count > 1
    # @order_number = order.number
    # @order_completed_at = order.completed_at
    # @order_payment_state = order.payment_state
    # @sold_inventory_units = Hash.new
    # @shipped_inventory_units = Hash.new
    # @backordered_inventory_units = Hash.new
    # @return_inventory_units = Hash.new
    instance = ShipmentPreviewObject.new
    
    order.line_items.each do |line_item|
      instance.increase_total(line_item.quantity)
    end
    instance.organize_inventory(order)
    return instance
  end
  
  def increase_total(amount)
    @total_products += amount
  end
  
  def self.category_size(tmphash)
    return 0 if tmphash.nil?
    count = 0;
    #puts tmphash
    tmphash.each_pair do |key, value|
      count = value.to_i + count.to_i
    end
    return count
  end
  
  def organize_inventory(order)
    @categorized_inventory = order.group_inventory()
    # @sold_inventory_units = tmpHash["sold"] if tmpHash.has_key?("sold")
    # @shipped_inventory_units = tmpHash["shipped"] if tmpHash.has_key?("shipped")
    # @backordered_inventory_units = tmpHash["backordered"] if tmpHash.has_key?("backordered")
    # @return_inventory_units = tmpHash["returned"] if tmpHash.has_key?("returned")
    total = 0
    @categorized_inventory.each_pair do |kay, value|
      total +=  ShipmentPreviewObject.category_size(value)
    end
    # puts total
    # puts @total_products
    raise "organize_inventory valid failed: " + order.number.to_s if (total != @total_products)
  end
end