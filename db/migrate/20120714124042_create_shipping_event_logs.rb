class CreateShippingEventLogs < ActiveRecord::Migration
  def change
    create_table :shipping_event_logs do |t|
      t.integer :shipping_event_id
      t.string  :process_state
      t.integer :shipment_manifest_id
      t.integer :line_number
      t.boolean :mail_send
      t.timestamps
    end
  end
end
