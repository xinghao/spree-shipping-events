module Spree
  class ManifestLine
    
    PRODUCT_DESCRIPTION = 'Description of Article'
    TRACKING_NUMBER = 'Consignment No.'
    DELIVERY_INSTRUCTION = 'Delivery Instruction'
    
    attr_accessor :mail_send, :shipment_manifest, :process_state, :process_msg, :skip, :multiple_product, :line_number, :valid, :warning, :msg, :warning_msg, :order, :shipping_events, :inventory_units, :tracking_number, :product_description, :delivery_instruction
    
    def initialize(csv_line, no, shipment_manifest)
      @line_number = no
      @shipment_manifest = shipment_manifest
      @tracking_number = @product_description = @delivery_instruction = nil
      @tracking_number = csv_line[TRACKING_NUMBER].strip if !csv_line[TRACKING_NUMBER].blank?
      @product_description = csv_line[PRODUCT_DESCRIPTION].strip if !csv_line[PRODUCT_DESCRIPTION].blank?
      @delivery_instruction = csv_line[DELIVERY_INSTRUCTION].strip if !csv_line[DELIVERY_INSTRUCTION].blank?
      @shipping_events = Array.new
      @inventory_units = Array.new
      @multiple_product = false
      @skip = false
      @valid = false
      @warning = false
      @mail_send = false
      @msg = ""
      @warning_msg = ""
      
      if !@delivery_instruction.blank? && @delivery_instruction.downcase == 'skip'
        @skip = true
        @warning_msg = "This order will be handled by manually."
        @valid = true
        return  
      end 
      return validate()
    end
        
    def validate()
      
      if @tracking_number.blank?
        @msg = "#{TRACKING_NUMBER} is blank"
        return 
      end
      
      if @product_description.blank?
        @msg = "#{PRODUCT_DESCRIPTION} is blank"
        return 
      end 

      if @delivery_instruction.blank?
        @msg = "#{DELIVERY_INSTRUCTION} is blank"
        return 
      end
      
       
      @valid = valid_product_description();
      return @valid;
    end
    
    def valid_product_description()
      reg = /\[(.*)\]:\[(.*)\]:\[(.*)\]/
      md = reg.match(@product_description)
      
      # make sure it is match the format
      if (md.size != 4)
        @msg = "#{PRODUCT_DESCRIPTION} is not formated as [order]:[shippine_events]:[inventory_unit_ids]"
        return false
      end
      
      shipping_event_numbers = md[2].split(",")
      inventory_unit_ids = md[3].split(",")  
      
        
      # make sure order is exist
      order_number = md[1]
      @order = Spree::Order.includes(:shipments => [:shipping_events => :inventory_units]).find_by_number(order_number)
      
      if @order.blank?
        @msg = "Can not find order #{order_number}"
        return false
      end      

      # make sure shipping events and inverntory units are 1 to 1
      if(shipping_event_numbers.size != inventory_unit_ids.size)
        @msg = "shippine_events and inventory_unit_ids size not matched"
        return false        
      end
      
      if inventory_unit_ids.size > 1
        @multiple_product = true
        @warning_msg += "This order includes multiple products. please make sure all products been shipped!!"
        @warning = true             
      end
      
      # if order has been shipped set valid equals true and puts warning message
      if @order.shipment_state == 'shipped'
        @warning_msg += "This order has already been shipped. Current line will be skipped; "
        @warning = true    
      end
      
      # make sure shipping events and inventory_units are matched
      shipping_event_numbers.each do |se_number|
        se = order.shipments.first.shipping_events.detect {|se| se.number == se_number}
        if se.nil?
          @msg = "Order does not have this event #{se_number}."
          return false
        end
      
        @shipping_events.push(se);
        
        #warning if it is already been shipped
        if !se.tracking.blank?
          @warning_msg += "Shipping event #{se_number} has been shipped; "
          @warning = true          
        end
        
        
        if !inventory_unit_ids.include?(se.inventory_units.first.id.to_s)
          @msg = "inventory and shipping events are not matched"
          return false          
        end
        
        @inventory_units.push(se.inventory_units.first)
        #make inventory unit state is right
        if se.inventory_units.first.state == "shipped"
          @warning_msg += "inventory #{se.inventory_units.first.id} has been shipped;"
          @warning = true
        elsif se.inventory_units.first.state != "sold"
          @msg = "inventory #{se.inventory_units.first.id} is #{se.inventory_units.first.state} currently?"
          return false          
        end
      end
      
      return true      
    end
    
    def process()
      if (@valid)
        if (@skip)
          @process_state = "skip by instruction";
        else
          @inventory_units.each do |unit|
            unit.state = 'shipped';
            unit.save
          end
          
          se_log_list = Array.new
          changed = false
          @shipping_events.each do |se|
            se_log = ShippingEventLog.new

            if (se.tracking.blank?)   
              changed = true         
              se.tracking = @tracking_number
              se.shipped_at = Time.now
              se.save
              se_log.process_state = "processed"
            else
              se_log.process_state = "skipped"
            end
                        
            se_log.shipping_event = se
            se_log.shipment_manifest = @shipment_manifest
            se_log.line_number = @line_number
            se_log_list.push se_log
          end
  
          @process_state = "processed";        
          stop_sending_mail = false
          shipment = @order.shipments.first
          if shipment.all_shipped? && shipment.state != "shipped"
            shipment.state = "shipped"
            shipment.update!(@order)
            @order.shipment_state = shipment.state
            @order.save
            if (@order.shipment_state != 'shipped' || shipment.state != 'shipped')  
              @process_state = "error. please contact support to manually correct order and send mail";
              stop_sending_mail = true; # should manually correct order and send mail
            end
          end
          
          if (!stop_sending_mail && changed) 
            shipment.send_shipment_mail 
            @mail_send = true
          end
          
          begin
            se_log_list.each do |se_log|
              se_log.mail_send = @mail_send;
              se_log.save
            end
          rescue
            # should not stop the whole process since mail has been sent.
          end   
        end    
      else
        @process_state = "validation failed";
      end
    end
    
    def to_s()
     ret = ""
     ret = "Track Number: " + @tracking_number if !@tracking_number.blank?
     ret += ", Product Description: " + @product_description if !@product_description.blank?
     ret += ", Delivery Instruction: " + @delivery_instruction if !@delivery_instruction.blank?
     return ret
    end
  end
end