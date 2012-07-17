class CreateShipmentManifests < ActiveRecord::Migration
  def change
    create_table :spree_shipment_manifests do |t|
      t.timestamp :uploaded_at
      t.timestamp :commit_at
      t.integer :user_id
      t.has_attached_file :avatar
      t.timestamps
    end
  end
end
