class CreateShippingEvents < ActiveRecord::Migration
  def change
    create_table :shipping_events do |t|

      t.timestamps
    end
  end
end
