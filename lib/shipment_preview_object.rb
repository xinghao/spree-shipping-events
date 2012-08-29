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
  @products = nil
  
  def initialize
    @categorized_inventory = Hash.new
    @total_products = 0
    @products = Hash.new
  end

  
  # def get_products_overview()
  #   return @products
  # end
    
  def self.build_display_data(start_from, end_to)
    
    display_hash = Hash.new
        
    o = Spree::Order.find_by_number 'R748506805'
    if (start_from.blank? && end_to.blank?)
      select = Spree::Order.includes(:ship_address, :inventory_units, :line_items, :shipments => :shipping_events).where("state = 'complete' and payment_state = 'paid' and completed_at > ?", o.completed_at)
    elsif (end_to.blank?)
      select = Spree::Order.includes(:ship_address, :inventory_units, :line_items, :shipments => :shipping_events).where("state = 'complete' and payment_state = 'paid' and completed_at > ? and completed_at >= ?", o.completed_at, start_from)
    elsif (start_from.blank?)
      select = Spree::Order.includes(:ship_address, :inventory_units, :line_items, :shipments => :shipping_events).where("state = 'complete' and payment_state = 'paid' and completed_at > ? and completed_at < ?", o.completed_at, end_to)
    else
      select = Spree::Order.includes(:ship_address, :inventory_units, :line_items, :shipments => :shipping_events).where("state = 'complete' and payment_state = 'paid' and completed_at > ? and completed_at >= ? and completed_at < ?", o.completed_at, start_from, end_to)
    end
    
    select.order("completed_at asc").find_each(:batch_size => 100) do |order|
      if !order.shipments.first.shipping_events.present?
        puts "No shipping events: #{order.number}"
        next
      end 
      
      if !order.shipments.first.all_shipped? && order.need_ship?
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
    raise "can not do with mulitple shippments in one order #{order.number}" if order.shipments.count > 1
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
#      instance.increase_products(line_item)
    end
    instance.organize_inventory(order)
    return instance
  end
  
  def increase_total(amount)
    @total_products += amount
  end
  
  def increase_products(line_item)
    if @products.has_key?(line_item.variant_id)
      @products[line_item.variant_id] =+ line_item.quantity;
    else
      @products[line_item.variant_id] = line_item.quantity;
    end
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