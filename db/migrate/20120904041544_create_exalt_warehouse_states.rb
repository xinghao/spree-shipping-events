class CreateExaltWarehouseStates < ActiveRecord::Migration
  def change
    create_table :exalt_warehouse_states do |t|
      t.integer :order_id
      t.string :reference1
      t.string :reference2
      t.string :reference3
      t.string :state          
      t.timestamps
    end
    add_index :exalt_warehouse_states, [:order_id]
    add_index :exalt_warehouse_states, [:reference1, :reference3]
    add_index :exalt_warehouse_states, [:state]
  end
end
