class CreateShippingOutputManifests < ActiveRecord::Migration
  def change
    create_table :spree_shipping_output_manifests do |t|
      t.integer :user_id
      t.has_attached_file :avatar
      t.timestamps
    end
  end
end
