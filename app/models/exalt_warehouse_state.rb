class ExaltWarehouseState < ActiveRecord::Base
  belongs_to :order, :class_name => "Spree::Order"
  
  RECEIVED = "received"
  PENDING = "pending"
  PROCESSED = 'processed'
  SHIPPED = "shipped"
  CANCELED = "cancelled"
  
  def self.make_hash_hash()
    exalt_warehouse_states = ExaltWarehouseState.where("state = ? or state = ? or state = ?", ExaltWarehouseState::RECEIVED, ExaltWarehouseState::PENDING , ExaltWarehouseState::PROCESSED);
    ret_hash = Hash.new
    exalt_warehouse_states.each do |ews|
      hash = "#{ews.reference1}-#{ews.reference2}-#{ews.reference3}"
      raise "duplicate entries for exalt warehouse #{ews.id.to_s}"if ret_hash.has_key?(hash)
      ret_hash[hash] = ews.id
    end
    raise "duplicate entries in exalt warehouse state" if ret_hash.size != exalt_warehouse_states.size
    return ret_hash
  end
  
  def self.get_inventory_units_id_list(order)      
      pending_iu_ids = Hash.new
      order.exalt_warehouse_states.each do |exalt_warehouse_state|
        reference3 = exalt_warehouse_state.reference3
        reference3 = Spree::LongStringMap.map(reference3);
        # puts exalt_warehouse_state.id.to_s
        # puts reference3
        raise "exalt warehouse status reference 3 is empty for order #{order.number}" if reference3.blank? 
        ius = reference3.split("-")
        ius.each do |iu_id|
          raise "exalt warehouse status broken for order #{order.number}, inventory id is duplicated" if pending_iu_ids.has_key?(iu_id)
          pending_iu_ids[iu_id.to_i] = exalt_warehouse_state.state
        end
      end
      return pending_iu_ids  
  end
end
