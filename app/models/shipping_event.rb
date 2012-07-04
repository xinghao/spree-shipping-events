require 'csv'

class ShippingEvent < ActiveRecord::Base
  belongs_to :shipment, :class_name => "Spree::Shipment"
  has_many :inventory_shipping_events, :class_name => "InventoryShippingEvent"
  has_many :inventory_units, :class_name => "Spree::InventoryUnit", :through => :inventory_shipping_events
  
  before_create :generate_event_number
  accepts_nested_attributes_for :inventory_units
  validates :shipment, :presence => true
#  attr_accessor :tracking, :update_shipped_at
  before_save :update_shipped_at
  after_save :update_inventory_units_state
  
  scope :shipped, where("shipped_at is not null and shipment_id is not null")
  scope :un_shipped, where("shipped_at is null  and shipment_id is not null")
  
  def is_shipped?
    if shipped_at != nil 
      return true
    else
      return false
    end
  end
  
  def has_backordered_inventory?
    return true if inventory_units.first.state == 'backordered'
  end
  
# C,,,S9,,Alicia Fitzgerald,,155 Doncatser Rd,,,,Balwyn North,VIC,3104,AU,,N,,
# A,,,,,,,,,,,,,,N,N,N,N,
# C,,,Contract Charge Code,,Name,Clients Business Name,Address 1,Address 2 ,Address 3,Address 4,Suburb,State,Post Code,AU,,,,Products rthat they ordered
# A,Weight ,Length,Width,Height,QTY,Article Description,,,,,,,,,,,,

  def valid_products_number()
    
  end
  
  
  #only use it for test
  def self.output_csv_file(file_name)
    
    contract_charge_code = "S9"
    
    business_name = ""
        
    CSV.open(file_name, "wb") do |csv|
      Spree::Order.where("state = 'complete' and payment_state = 'paid'").order("id asc").all.each do |order|
        puts order.number
        name = order.ship_address.full_name        
        address1 = order.ship_address.address1
        address2 = order.ship_address.address2
        address3 = ""
        address4 = ""
        suburb = "" #order.ship_address.city
        state = order.ship_address.state_name
        postcode = order.ship_address.zipcode
        
        order.shipments.each do |s|
          raise "address valid error" if !s.valid_address
          s.group_sold_inventory_units.each_pair do |product_id, value|
            p = Spree::Product.find product_id
            csv << ["C","","",contract_charge_code,"",name,"",address1,address2,address3,address4,suburb,state,postcode,"AU","","N","","",p.name]
            csv << ["A",p.weight,p.depth,p.width,p.height,value["quantity"],p.short_description.to_s.truncate(250),"","","","","","","","N","N","N","N",""]
          end
          
        end
        
        
         
      end

      
    end
  end
    
  private
    def update_inventory_units_state
      if self.is_shipped?
        self.inventory_units.each do |unit|
          if unit.state != 'shipped'
            unit.send(:ship)
            unit.save
          end
        end
      end
    end
    
    def update_shipped_at
      self.shipped_at = Time.now if self.tracking_changed? && !self.tracking.nil? && self.tracking != ""
    end
    
    def generate_event_number
      return self.number unless self.number.blank?
      record = true
      while record
        random = "SE#{Array.new(11){rand(9)}.join}"
        record = self.class.where(:number => random).first
      end
      self.number = random
    end
  
end
