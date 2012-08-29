class AddCarrierAndUrlToSe < ActiveRecord::Migration
  def change
    add_column :shipping_events, :carrier, :string, :limit => 255
    add_column :shipping_events, :carrier_query_url, :string, :limit => 255
  end
end
