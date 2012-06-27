class InventoryShippingEvent < ActiveRecord::Base
  belongs_to :shipping_event, :class_name => "ShippingEvent"
  belongs_to :inventory_unit, :class_name => "Spree::InventoryUnit"

  def self.build(inventory_unit)
    ise = InventoryShippingEvent.new
#    ise.shipping_event = shipping_event
    ise.inventory_unit = inventory_unit
#    ise.save
    return ise
  end
  
end
