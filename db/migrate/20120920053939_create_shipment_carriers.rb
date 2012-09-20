class CreateShipmentCarriers < ActiveRecord::Migration
  def change
    create_table :shipment_carriers do |t|
      t.string :name
      t.string :query_url
      t.string :presentation
      t.timestamps
    end    
    add_index :shipment_carriers, [:name]
  end
end
