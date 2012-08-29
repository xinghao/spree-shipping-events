module Spree
  class ManifestLineExalt
    

    TRACKING_NUMBER = 'Consignment No.';
    ORDER_NUMBER = "Reference 1";
    SE_NUMBERS = "Reference 2";
    IU_IDS = "Reference 3";
    CARRIER = "Carrier";
    SHIPPING_UNITS_AMOUNT = "Shipping Units";
    ORDER_QTY = "Ord Qty";
    SHIP_QTY = "Ship Qty";
    SHORT_QTY = "Short Qty";
    SHIPPED = "Shipped"    
    
    attr_accessor :mail_send, :shipment_manifest, :process_state, :process_msg, :skip, :multiple_product, :line_number, :valid, :warning, :msg, :warning_msg, :order, :shipping_events, :inventory_units, :tracking_number, :se_numbers, :iu_ids, :order_qty, :shipping_units_amount, :ship_qty, :short_qty, :shipped, :carrier, :order_number, :already_processed
    
    def initialize(csv_line, no, shipment_manifest)
      @line_number = no
      @shipment_manifest = shipment_manifest
      @tracking_number = @se_numbers = @iu_ids = nil
      @order_number = csv_line[ORDER_NUMBER].strip if !csv_line[ORDER_NUMBER].blank?
      @tracking_number = csv_line[TRACKING_NUMBER].strip if !csv_line[TRACKING_NUMBER].blank?
      @se_numbers = csv_line[SE_NUMBERS].strip if !csv_line[SE_NUMBERS].blank?
      @iu_ids = csv_line[IU_IDS].strip if !csv_line[IU_IDS].blank?   
      @carrier = csv_line[CARRIER].strip if !csv_line[CARRIER].blank?
      @shipping_units_amount = csv_line[SHIPPING_UNITS_AMOUNT].strip if !csv_line[SHIPPING_UNITS_AMOUNT].blank?
      @order_qty = csv_line[ORDER_QTY].strip if !csv_line[ORDER_QTY].blank?
      @ship_qty = csv_line[SHIP_QTY].strip if !csv_line[SHIP_QTY].blank?
      @short_qty = csv_line[SHORT_QTY].strip if !csv_line[SHORT_QTY].blank?
      @shipped = csv_line[SHIPPED].strip if !csv_line[SHIPPED].blank?
      
      @shipping_events = Array.new
      @inventory_units = Array.new
      @multiple_product = false
      @skip = false
      @valid = false
      @warning = false
      @already_processed = false
      @mail_send = false
      # @skip_mail = skip_mail
      # @only_send_to_backorder_users = only_send_to_backorder_users
      @msg = ""
      @warning_msg = ""
      
      if !@se_numbers.blank? && @se_numbers.downcase == 'skip'
        @skip = true
        @warning_msg = "This order will be handled by manually."
        @valid = true
        return  
      end 
      
      if (!@se_numbers.blank? && @se_numbers.match(/^lsm/i))
        @warning_msg += "Long string mapping for se numbers..."
        #@warning = true             
        lsm = Spree::LongStringMap.find_by_number @se_numbers
        @se_numbers = lsm.value 
      end
      
      if (!@iu_ids.blank? && @iu_ids.match(/^lsm/i))
        @warning_msg += "Long string mapping for iu ids.."
        #@warning = true             
        lsm = Spree::LongStringMap.find_by_number @iu_ids
        @iu_ids = lsm.value 
      end
      
      return validate()
    end
        
    def validate()
      
      if @tracking_number.blank?
        @msg = "#{TRACKING_NUMBER} is blank"
        return 
      end
      
      if @se_numbers.blank?
        @msg = "#{SE_NUMBERS} is blank"
        return 
      end 

      if @iu_ids.blank?
        @msg = "#{IU_IDS} is blank"
        return 
      end
      
      if @order_number.blank?
        @msg = "#{ORDER_NUMBER} is blank"
        return 
      end

        
      @shipping_units_amount = get_quantity(@shipping_units_amount, SHIPPING_UNITS_AMOUNT)
      return if  @shipping_units_amount < 0
        
      @order_qty = get_quantity(@order_qty, ORDER_QTY)
      return if  @order_qty < 0

      @ship_qty = get_quantity(@ship_qty, SHIP_QTY)
      return if  @ship_qty < 0

      @short_qty = get_quantity(@short_qty, SHORT_QTY)
      return if  @short_qty < 0
            
      if @shipped.blank?
        @msg = "#{SHIPPED} is blank"
        return 
      end
       
      @valid = valid_order();
      return @valid;
    end
    
    def get_quantity(str, str_name)
      if str.blank?
        @msg = "#{str_name} is blank"
        return -1       
      else
        begin 
          return str.to_i
        rescue
          @msg = "#{str_name} is not a digit"
          return -1
        end
      end      
    end
    
    
    def valid_order()
                    
      # make sure order is exist      
      @order = Spree::Order.includes(:shipments => [:shipping_events => :inventory_units]).find_by_number(@order_number)
      
      if @order.blank?
        @msg = "Can not find order #{@order_number}"
        return false
      end      

      se_numbers_list = @se_numbers.split("-");
      iu_ids_list = @iu_ids.split("-");
      # make sure shipping events and inverntory units are 1 to 1
      if(se_numbers_list.size != iu_ids_list.size)
        @msg = "shippine_events and inventory_unit_ids size not matched"
        return false        
      end
      
      if iu_ids_list.size > 1
        @multiple_product = true
        @warning_msg += "This order includes multiple products. please make sure all products been shipped!!"
        #@warning = true             
      end
      
      if @order.shipment_state == 'shipped' && @order.need_ship?
        @msg = "order's shipment_state is wrong";
        return false        
      end
      
      # if order has been shipped set valid equals true and puts warning message
      if @order.shipment_state == 'shipped'
        @warning_msg += "This order has already been shipped. Current line will be skipped; "
        @already_processed = true
        @warning = true    
      end
      
      processed_se_count = 0
      # make sure shipping events and inventory_units are matched
      se_numbers_list.each do |se_number|
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
        
        if !se.tracking.blank? && se.inventory_units.first.state != "shipped"
          @msg = "se has tracking number but inventory #{se.inventory_units.first.id} state is not shipped!"
          return false
        end
          
        if !iu_ids_list.include?(se.inventory_units.first.id.to_s)
          @msg = "inventory and shipping events are not matched"
          return false          
        end
        
        @inventory_units.push(se.inventory_units.first)
        #make inventory unit state is right
        if se.inventory_units.first.state == "shipped"
          @warning_msg += "inventory #{se.inventory_units.first.id} has been shipped;"
          processed_se_count += 1;
          @warning = true
        elsif se.inventory_units.first.state != "sold"
          @msg = "inventory #{se.inventory_units.first.id} is #{se.inventory_units.first.state} currently?"
          return false          
        end
      end
      
      if processed_se_count == se_numbers_list.size && !@already_processed
         @already_processed = true
         @warning_msg += "This line has been imported before!!!"         
         @warning = true         
      end
      
      return true      
    end
    
    

    def process(skip_mail, only_send_to_backorder)
      if (@valid)
        if (@skip)
          @process_state = 1
          @process_msg = "skip by instruction";
        else
          @inventory_units.each do |unit|
            if unit.state != 'shipped'
              unit.state = 'shipped';
              unit.save
            end
          end
          
          se_log_list = Array.new
          changed = false
          skip_count = 0
          @shipping_events.each do |se|
            se_log = ShippingEventLog.new

            if (se.tracking.blank?)   
              changed = true
              if !@tracking_number.blank?
                se.tracking = @tracking_number
              else
                se.tracking = "Customized"
              end
              
              if @shipped.blank?
                se.shipped_at = Time.now
              else
                se.shipped_at = @shipped
              end              
              se.save
              se_log.process_state = "processed"
            else              
              skip_count += 1;
              se_log.process_state = "skipped"
            end
                        
            se_log.shipping_event = se
            se_log.shipment_manifest = @shipment_manifest
            se_log.line_number = @line_number
            se_log_list.push se_log
          end
  
          if (@shipping_events.size > skip_count)
            @process_state = 0;
            @process_msg = "processed";
          else
            @process_state = 2;
            @process_msg = "already processed";
          end            
                      
          stop_sending_mail = false
          shipment = @order.shipments.first
          if shipment.all_shipped? && shipment.state != "shipped"
            shipment.state = "shipped"
            shipment.set_tracking_number
            shipment.update!(@order)
            @order.shipment_state = shipment.state
            @order.save
            if (@order.shipment_state != 'shipped' || shipment.state != 'shipped')  
              @process_state = 3 
              @process_msg = "error. please contact support to manually correct order and send mail";
              stop_sending_mail = true; # should manually correct order and send mail
            end
          end
          
          if (!stop_sending_mail && changed && (!skip_mail || (only_send_to_backorder_users && !shipment.all_shipped?))) 
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
        @process_state = 4
        @process_msg = "validation failed";
      end
    end
    
    def process_println()
      puts "Line No: #{@line_number}, #{ORDER_NUMBER}: #{@order_number}, #{SE_NUMBERS}: #{@se_numbers}, #{IU_IDS}: #{@iu_ids}"
      puts "    #{TRACKING_NUMBER}: #{@tracking_number}, #{CARRIER}: #{@carrier}, #{SHIPPING_UNITS_AMOUNT}: #{@shipping_units_amount}, #{ORDER_QTY}: #{@order_qty}, #{SHIP_QTY}: #{@ship_qty}, #{SHORT_QTY}: #{@short_qty}, #{SHIPPED}: #{@shipped}"
      puts "Process: #{@process_msg}"      
    end
    
    def println()
      puts "Line No: #{@line_number}, #{ORDER_NUMBER}: #{@order_number}, #{SE_NUMBERS}: #{@se_numbers}, #{IU_IDS}: #{@iu_ids}"
      puts "    #{TRACKING_NUMBER}: #{@tracking_number}, #{CARRIER}: #{@carrier}, #{SHIPPING_UNITS_AMOUNT}: #{@shipping_units_amount}, #{ORDER_QTY}: #{@order_qty}, #{SHIP_QTY}: #{@ship_qty}, #{SHORT_QTY}: #{@short_qty}, #{SHIPPED}: #{@shipped}"
      if !@valid
        puts "    Validate: Error"
      elsif @skip
        puts "    Validate: Skip"
      elsif @already_processed
        puts "    Validate: Processed"  
      elsif @warning
        puts "    Validate: Warning"      
      else
        puts "    Validate: Pass"
      end 
      
      if !@valid
        puts "    Message: #{@msg}"
      elsif @skip
        puts "    Message: #{@warning_msg}"
      elsif @already_processed
        puts "    Message: #{@warning_msg}"        
      elsif @warning
        puts "    Message: #{@warning_msg}"
      else
        puts "    Message: #{@warning_msg}" if !@warning_msg.blank? 
      end       
    end
  end
end