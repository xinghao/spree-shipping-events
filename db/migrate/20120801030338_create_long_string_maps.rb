class CreateLongStringMaps < ActiveRecord::Migration
  def change
    create_table :spree_long_string_maps do |t|
      t.string :number
      t.text :value
      t.timestamps
    end
    add_index :spree_long_string_maps, [:number]
  end
end
