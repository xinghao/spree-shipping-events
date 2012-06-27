class CreateInventoryShippingEvents < ActiveRecord::Migration
  def change
    create_table :inventory_shipping_events do |t|
      t.integer :shipping_event_id
      t.integer :inventory_unit_id
      t.timestamps
    end
    add_index :inventory_shipping_events, [:shipping_event_id]
    add_index :inventory_shipping_events, [:inventory_unit_id]
    
  end
end
