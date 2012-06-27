class CreateShippingEvents < ActiveRecord::Migration
  def change
    create_table :shipping_events do |t|
      t.string :number
      t.integer :shipment_id
      t.string :tracking
      t.timestamp :shipped_at
      t.timestamps
    end
    add_index :shipping_events, [:shipment_id]
     add_index :shipping_events, [:number]
  end
end
