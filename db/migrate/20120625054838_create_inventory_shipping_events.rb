class CreateInventoryShippingEvents < ActiveRecord::Migration
  def change
    create_table :inventory_shipping_events do |t|

      t.timestamps
    end
  end
end
