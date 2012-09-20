module Spree
  class ManifestLineExalt
    

    TRACKING_NUMBER = 'ConsignmentNumber';
    ORDER_NUMBER = "Reference1";
    SE_NUMBERS = "Reference2";
    IU_IDS = "Reference3";
    CARRIER = "Carrier";
    SHIPPING_UNITS_AMOUNT = "ShippingUnits";
    ORDER_QTY = "OrderQty";
    SHIP_QTY = "ShipQty";
    SHORT_QTY = "ShortQty";
    SHIPPED = "ShippedOn"
    PRODUCT_CODE = "ProductCode"
    PRODCUT_DESCRIPTION = "Description"
    ORDER_NOTE = "OrderNotes"
        
    STATUS = "Status"
    attr_accessor :mail_send, :csv_line_amount, :reference1, :need_process, :manual_skip, :ware_house_state_string, :ware_house_state, :order_note, :shipment_manifest, :process_state, :process_msg, :skip, :multiple_product, :valid, :warning, :msg, :warning_msg, :order, :shipping_events, :inventory_units, :tracking_number, :se_numbers, :iu_ids, :order_qty, :shipping_units_amount, :ship_qty, :short_qty, :shipped, :carrier, :order_number, :already_processed, :status, :query_url
    
    def parse_single_line(reference1, csv_line)
      ret_hash = {:iu_ids_array=> nil, :order_note => nil, :se_numbers_array=> nil, :tracking_number => nil, :ware_house_state => nil, :shipping_units_amount => 0, :order_qty => 0, :ship_qty => 0, :short_qty => 0, :shipped => nil, :status => nil, :carrier => nil}
      
      if !csv_line[ORDER_NUMBER].blank?
        ref1 = csv_line[ORDER_NUMBER].strip
        raise "Reference1 not matched #{reference1}" if reference1 != ref1         
      else
        raise "Does not have reference1 for #{reference1}" 
      end

      
      if !csv_line[IU_IDS].blank?
        reference3 = iu_ids = csv_line[IU_IDS].strip
        iu_ids = Spree::LongStringMap.map(iu_ids); 
        ret_hash[:iu_ids_array] = iu_ids.split("-")
      else
        raise "Does not have iu numbers for #{reference1}"
      end 
      
      ret_hash[:ware_house_state] = ExaltWarehouseState.where("reference1 = ? and reference3 = ?", reference1, iu_ids).first      

      if !csv_line[SE_NUMBERS].blank?
        reference2 = se_numbers = csv_line[SE_NUMBERS].strip        
        raise "reference2 in manifest does not matched in our internal database! #{reference1}" if !ret_hash[:ware_house_state].nil? && ret_hash[:ware_house_state].reference2 != se_numbers
        se_numbers = Spree::LongStringMap.map(se_numbers);
        ret_hash[:se_numbers_array] = se_numbers.split("-")
      else
         raise "Does not have se numbers for #{reference1}"
      end
      
      if ret_hash[:ware_house_state].nil?
         ews = ExaltWarehouseState.new
         ews.reference1 = reference1
         ews.reference2 = reference2
         ews.reference3 = reference3
         ews.state = ExaltWarehouseState::RECEIVED
        ret_hash[:ware_house_state] = ews
      end 
                                          
      ret_hash[:tracking_number] = csv_line[TRACKING_NUMBER].strip if !csv_line[TRACKING_NUMBER].blank?      
      ret_hash[:shipping_units_amount] = csv_line[SHIPPING_UNITS_AMOUNT].strip.to_i if !csv_line[SHIPPING_UNITS_AMOUNT].blank?
      ret_hash[:order_qty] = csv_line[ORDER_QTY].strip.to_i if !csv_line[ORDER_QTY].blank?
      ret_hash[:ship_qty] = csv_line[SHIP_QTY].strip.to_i if !csv_line[SHIP_QTY].blank?
      ret_hash[:short_qty] = csv_line[SHORT_QTY].strip.to_i if !csv_line[SHORT_QTY].blank?
      ret_hash[:shipped] = csv_line[SHIPPED].strip if !csv_line[SHIPPED].blank?
      ret_hash[:status] = csv_line[STATUS].strip.downcase if !csv_line[STATUS].blank?
      ret_hash[:order_note] = csv_line[ORDER_NOTE].strip.downcase if !csv_line[ORDER_NOTE].blank?
      
      
      if !csv_line[PRODUCT_CODE].blank?
        product_code = csv_line[PRODUCT_CODE].strip 
      else
        raise "Product code is empty for #{reference1}"
      end
      
      if !csv_line[CARRIER].blank?
        ret_hash[:carrier] = csv_line[CARRIER].strip
      else
        raise "Carrier is empty for #{reference1}"
      end
      
      if !csv_line[PRODCUT_DESCRIPTION].blank?
        product_description = csv_line[PRODCUT_DESCRIPTION].strip 
      else
        raise "Product description is empty for #{reference1}"
      end
      
      iu_id = ret_hash[:iu_ids_array][0]
      if @order.state != 'canceled'
        iu = Spree::InventoryUnit.find iu_id
        raise "inventory id does not exist: #{iu_id} for reference1: #{reference1}" if iu.nil?
        if iu.variant.sku != product_code || iu.variant.name_with_options_text.strip != product_description.strip
          puts "!!----------------------------------------!!"
          puts "Product code and product description not matched here!!!! for reference1: #{reference1} and iu_id: #{iu_id}, #{iu.variant.sku} != #{product_code}, #{iu.variant.name_with_options_text.strip} != #{product_description.strip}" 
          puts "!!----------------------------------------!!" 
        end
      end      
      raise "order qty is empty for #{reference1}" if ret_hash[:order_qty] == 0
      
      raise "shippedon is empty for a shipped entry for #{reference1}" if ret_hash[:status].downcase == ExaltWarehouseState::SHIPPED && ret_hash[:shipped].blank?  
      return ret_hash       
    end
    
    def initialize(reference1, csv_lines, shipment_manifest)
      #init
      @shipment_manifest = shipment_manifest
      @csv_line_amount = csv_lines.size
      @reference1 = reference1
      @tracking_number = @se_numbers = @iu_ids = nil

      @shipping_units_amount = 0
      @order_qty = 0
      @ship_qty = 0
      @short_qty = 0
      @shipped = nil
      @manual_skip = false
      @need_process = false

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
      se_numbers_list = Array.new
      iu_ids_list = Array.new
      @ware_house_state = Array.new
      @tracking_number = nil
      @status = nil
      @order_note = nil
      @ware_house_state_string = nil
      @carrier = nil
      @query_url = nil
      
      raise "Does not have reference1" if reference1.blank?
      if Spree::ManifestLineExalt.manual_skip?(reference1)
        @manual_skip = true;
        @valid = true;
        return true;
      end
                 
      reference1s= ShipInfo::Exalt.parse_reference1(reference1)
      @order_number = reference1s[:order_number]
      raise "reference1 is not well formated #{reference1}" if @order_number.blank?
      
      @order = Spree::Order.includes(:shipments => [:shipping_events => :inventory_units]).find_by_number(@order_number)
      raise "Order does not exist for Reference1 #{reference1}" if @order.nil?
      
      status_tmp = nil
      #{:iu_ids_array=> nil, :se_numbers_array=> nil, :tracking_number => nil, :ware_house_state => nil, :shipping_units_amount => 0, :order_qty => 0, :ship_qty => 0, :short_qty => 0, :shipped => nil, :status => nil}
      csv_lines.each do |csv_line|
        ret = parse_single_line(reference1, csv_line);
        @shipping_units_amount += ret[:shipping_units_amount]
        @order_qty += ret[:order_qty]
        @ship_qty += ret[:ship_qty]
        @short_qty += ret[:short_qty]
        @shipped = DateTime.strptime(ret[:shipped], '%d/%m/%Y').to_time if !ret[:shipped].blank? 
        
        # valid tracking number
        if !@tracking_number.blank? && ret[:tracking_number] != @tracking_number
          raise "Tracking number is not consistent for Reference1 #{reference1}"
        elsif !ret[:tracking_number].blank?
          @tracking_number = ret[:tracking_number]
        end 

        # valid carrier
        if !@carrier.blank? && ret[:carrier] != @carrier
          raise "Carrier is not consistent for Reference1 #{reference1}"
        elsif !ret[:carrier].blank?
          @carrier = ret[:carrier]
        end 
                
        #valid status
        if !@status.blank? && ret[:status] != @status
          raise "mulitple status for Reference1 #{reference1}, #{@status} != #{ret[:status]}"
        else
          @status = ret[:status]
          if @status.blank?
            raise "status is empty for Reference1 #{reference1}"
          end
        end 
        
        #valid order note
        # if !@order_note.blank? && ret[:order_note] != @order_note
        #   raise "mulitple status for Reference1 #{reference1}"
        # elsif !ret[:order_note].blank?
        #   if ret[:order_note].downcase != 'CANCELLED. '.downcase && ret[:order_note].downcase != 'CANCELLED.'.downcase
        #     raise "Unknown order notes #{ret[:order_note]} for Reference1 #{reference1}"
        #   else
        #     @order_note = ret[:order_note]
        #     status_tmp = ExaltWarehouseState::CANCELED
        #   end
        # end 

        #valid warehouse state
        if !@ware_house_state_string.blank? && !ret[:ware_house_state].nil? && @ware_house_state_string != ret[:ware_house_state].state
          raise "mulitple ware house state for Reference1 #{reference1}"
        elsif !ret[:ware_house_state].nil?
          @ware_house_state.push ret[:ware_house_state]
          @ware_house_state_string = ret[:ware_house_state].state
        end 
        
          
          
        ret[:iu_ids_array].each do |iu_id|
          if iu_ids_list.include?(iu_id)
            raise "duplicate inventory id: #{iu_id} for reference1 #{reference1}"
          else
            iu_ids_list.push iu_id
          end
        end
        
        ret[:se_numbers_array].each do |se_number|
          if se_numbers_list.include?(se_number)
            raise "duplicate shipping event number #{se_number} for reference1 #{reference1}"
          else
            se_numbers_list.push se_number
          end
        end                
      end
      
            
      #@status = status_tmp if !status_tmp.blank?
      return validate(se_numbers_list, iu_ids_list)
    end
        
    def validate(se_numbers_list, iu_ids_list)
      
      if se_numbers_list.size == 0
        @msg = "#{SE_NUMBERS} is blank for order: #{@reference1}"
        return false
      end 

      if iu_ids_list.size == 0
        @msg = "#{IU_IDS} is blank for order: #{@reference1}"
        return false
      end

      #valid status is known to us
      if @status != ExaltWarehouseState::PENDING &&     
        @status != ExaltWarehouseState::PRCESSED &&
        @status != ExaltWarehouseState::SHIPPED &&
        @status != ExaltWarehouseState::CANCELED
        @msg = "unknow exalt warehouse status #{@status} for order: #{@reference1}"
        return false
      end   
      
      
      # check if internal warehouse state is match with manifest
      if !@ware_house_state_string.blank?
        if @ware_house_state_string == ExaltWarehouseState::SHIPPED && @status != ExaltWarehouseState::SHIPPED
          @msg = "bbq internal warehouse state is not matched with manifest for order: #{@reference1}"
          return false
        end
        
        if @ware_house_state_string == ExaltWarehouseState::CANCELED && @status != ExaltWarehouseState::CANCELED
          @msg = "bbq internal warehouse state is not matched with manifest for order: #{@reference1}"
          return false
        end
      end
        
      if @status == ExaltWarehouseState::SHIPPED && (@tracking_number.blank? || @ship_qty == 0 || @ship_qty != @order_qty)
        @msg = "shipped statndards not all met for order: #{@reference1}"
        return false
      end          
      
      if @status == ExaltWarehouseState::SHIPPED
        #validate carrier name
        raise "carrier can not be empty for Reference1 #{reference1}" if @carrier.blank?
        @query_url = ShipmentCarrier.get_query_url(@carrier)
        raise "Unknow carrier #{@carrier} for Reference1 #{reference1}" if @query_url.blank?        
      end

      if @status == ExaltWarehouseState::CANCELED && (!@tracking_number.blank? || @ship_qty != 0 )
        @msg = "canceled statndards not all met for order: #{@reference1}"
        return false
      end          
      
      if @status == ExaltWarehouseState::PENDING && ExaltWarehouseState::PENDING != @ware_house_state_string &&  ExaltWarehouseState::RECEIVED != @ware_house_state_string
        @msg = "Internal state not matched for pending state in manifest: #{@reference1}"
        return false
      end          

      @valid = valid_order(se_numbers_list, iu_ids_list)
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
    
    
    def valid_order(se_numbers_list, iu_ids_list)
                    
      # make sure order is exist      
      @order = Spree::Order.includes(:shipments => [:shipping_events => :inventory_units]).find_by_number(@order_number)
      
      if @order.blank?
        @msg = "Can not find order #{@order_number}"
        return false
      end      
      
      if @ware_house_state_string == @status
        @warning_msg += "This Reference1' has been imported before";
        @warning = true
        @skip = true
      else
        @need_process = true                 
      end

      
      if @ware_house_state_string == ExaltWarehouseState::CANCELED || @status == ExaltWarehouseState::CANCELED
          if @order.state != "canceled"
            @msg = "order state is not canceled" 
            return false
          end        
      end
      
      
      if @status == ExaltWarehouseState::CANCELED || @order.state == 'canceled'
        
        return true
      end     

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
        raise "order shipment state is wrong #{order.number}" if @order.shipment.state != 'shipped'
        @order.inventory_units.each do |iu|
          raise "order shipment state is wrong #{order.number}" if iu.state != 'shipped'
        end 
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
        
        if !se.tracking.blank? && se.tracking != @tracking_number
          @msg = "se has tracking number but not matched with manifest #{se.tracking} != #{@tracking_number}"
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
      
      if @ware_house_state_string == ExaltWarehouseState::SHIPPED
        @inventory_units.each do |iu|
          if iu.state != "shipped"
            @msg = "inventory unit #{iu.id} state is wrong" 
            return false
          end
        end
        @shipping_events.each do |se|
          if se.tracking.blank? || se.tracking != @tracking_number
            @msg = "Shipping events #{se.number} tracking number is wront" 
            return false
          end
        end
      end
            
      if @inventory_units.size != @order_qty
        @msg = "order quantity is not much inventory size"
        return false
      end
            
      
      
      
      return true      
    end
    
    def process(skip_mail)
      if (@valid)
        if (@manual_skip)
          @process_state = 1
          @process_msg = "skip by email";
          return
        end     
        
        if !@need_process
          @process_state = 5
          @process_msg = "no changes";
          return
        end   
        
        if @status == ExaltWarehouseState::PENDING
          @process_state = 6
          @process_msg = "changing to pending";
          update_ews(@status)                    
        end
        
        if @status == ExaltWarehouseState::CANCELED
          @process_state = 7
          @process_msg = "changing to canceled";
          update_ews(@status)                    
        end

        if @status == ExaltWarehouseState::PRCESSED
          @process_state = 8
          @process_msg = "changing to processed";
          update_ews(@status)                    
        end
        
        if @status == ExaltWarehouseState::SHIPPED
          shipped(skip_mail)
          update_ews(@status)                 
        end                
        
      else
        @process_state = 4
        @process_msg = "validation failed";        
      end
    end

    def update_ews(state)
      @ware_house_state.each do |whs|
        whs.order = @order if whs.order_id == nil
        whs.state = state
        whs.save
      end
    end
    
    def shipped(skip_mail)

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
              
              if !@carrier.blank?
                se.carrier = @carrier
              end
                        
              se.save
              se_log.process_state = "processed"
            else              
              skip_count += 1;
              se_log.process_state = "skipped"
            end
                        
            se_log.shipping_event = se
            se_log.shipment_manifest = @shipment_manifest
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
          
          #if (!stop_sending_mail && changed && (!skip_mail || (only_send_to_backorder_users && !shipment.all_shipped?))) 
          if (!stop_sending_mail && changed && !skip_mail)
            shipment.reload.send_shipment_mail 
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
    
    def process_println()
      puts "Reference1: #{@reference1}"
      puts "    #{TRACKING_NUMBER}: #{@tracking_number}, #{CARRIER}: #{@carrier}, #{SHIPPING_UNITS_AMOUNT}: #{@shipping_units_amount}, #{ORDER_QTY}: #{@order_qty}, #{SHIP_QTY}: #{@ship_qty}, #{SHORT_QTY}: #{@short_qty}, #{SHIPPED}: #{@shipped}"
      puts "Process: #{@process_msg}"      
    end
    
    def println()
      puts "Reference1: #{@reference1}, Csv_lines: #{@csv_line_amount}, State: #{@status}"
      puts "    #{TRACKING_NUMBER}: #{@tracking_number}, #{CARRIER}: #{@carrier}, #{SHIPPING_UNITS_AMOUNT}: #{@shipping_units_amount}, #{ORDER_QTY}: #{@order_qty}, #{SHIP_QTY}: #{@ship_qty}, #{SHORT_QTY}: #{@short_qty}, #{SHIPPED}: #{@shipped}"
      if !@valid
        puts "    Validate: Error" + ", Needs processing: #{@need_process}"
      elsif @manual_skip
        puts "    Validate: Email Skip" + ", Needs processing: #{@need_process}"
      elsif @already_processed
        puts "    Validate: Processed"  + ", Needs processing: #{@need_process}"
      elsif @warning
        puts "    Validate: Warning"      + ", Needs processing: #{@need_process}"
      else
        puts "    Validate: Pass" + ", Needs processing: #{@need_process}"
      end 
      
      puts "    Internal warehourse state: #{@ware_house_state_string}"

      if !@valid
        puts "    Message: #{@msg}"
      elsif @manual_skip
        puts "    Message: #{@warning_msg}"
      elsif @already_processed
        puts "    Message: #{@warning_msg}"        
      elsif @warning
        puts "    Message: #{@warning_msg}"
      else
        puts "    Message: #{@warning_msg}" if !@warning_msg.blank? 
      end       
      puts "==========================================================="
    end

  
    def self.get_reference1(csv_line)
      if !csv_line[ORDER_NUMBER].blank?
        return csv_line[ORDER_NUMBER].strip;
      else
        return nil;
      end 
    end
  
    def self.manual_skip?(reference1)
      return reference1 =~ /^email/i
    end
  
  end    
end