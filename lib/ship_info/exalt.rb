module ShipInfo
  class Exalt < ShipInfo::BasicHandler
    HEADER = ["Reference1",  "Reference2",  "Reference3",  "Name",  "Company", "Address1",  "Address2",  "Suburb",  "State", "Postcode",  "Country", "TelephoneNumber", "EmailAddress",  "CustomerInstructions",  "WarehouseInstructions", "FreightInstructions", "ProductCode", "Quantity",  "Description", "ProductType", "ImageLink", "SupplierCode",  "CarrierServiceCode",  "IsATLRequired"]
    
    def mark_order(manifest_id, limit, validate)
      sm = Spree::ShippingOutputManifest.find manifest_id
      raise "Can not find manifest for id #{id}" if sm.blank?
            
      puts sm.avatar.url
      
      pass_count = 0;
      process_count = 0;
      error_count = 0;
      duplicate_count = 0;
      line_no = 1
      CSV.new(open(sm.avatar.url), :headers => :first_row).each do |line|
        line_no += 1;        
        break if (line_no - 1) > limit.to_i && limit > 0        
        reference1 = line[HEADER[0]].strip if !line[HEADER[0]].blank?
        reference2 = line[HEADER[1]].strip if !line[HEADER[1]].blank?
        reference3 = line[HEADER[2]].strip if !line[HEADER[2]].blank?
        raise "#{line_no.to_s}: reference is empty" if  reference1.blank? || reference2.blank? && reference3.blank?
        exalt_warehouse_state = ExaltWarehouseState.where("reference1 = ? and reference2 = ?", reference1, reference3).first
        raise "#{line_no.to_s}: shipping number is not matched!" if !exalt_warehouse_state.nil? && !exalt_warehouse_state.reference2 != reference2  
        
        if exalt_warehouse_state.nil?  
          reference1_hash = ShipInfo::Exalt.parse_reference1(reference1)
          order_number = reference1_hash[:order_number]
          reference1_iu_ids = reference1_hash[:iu_ids]
          if (order_number.blank? || reference1_iu_ids.blank?)
            puts "#{line_no.to_s} reference1[#{reference1}] parse error"
            error_count += 1;
            next
          end
          order = Spree::Order.find_by_number order_number
          if order.nil?
            puts "#{line_no.to_s} reference1[#{reference1}] order not exist"
            error_count += 1;
            next
          end
          #validate more, not now.........
          if !validate
            exalt_warehouse_state = ExaltWarehouseState.new
            exalt_warehouse_state.order_id = order.id
            exalt_warehouse_state.reference1 = reference1;
            exalt_warehouse_state.reference2 = reference2;
            exalt_warehouse_state.reference3 = reference3;
            exalt_warehouse_state.state = ExaltWarehouseState::RECEIVED
            exalt_warehouse_state.save
            process_count += 1
          end
          pass_count += 1
          sleep 0.01
        else
          if exalt_warehouse_state.state != ExaltWarehouseState::RECEIVED
            error_count += 1;
            puts "#{line_no.to_s} reference1[#{reference1}] has already been processed by warehouse"
            next
          end
          duplicate_count += 1;
        end
     end
     
     puts "Total: #{line_no - 1},  Valid Failed: #{error_count}, duplicated: #{duplicate_count}, Pass: #{pass_count}, Processed: #{process_count}" 
      
    end
    
    #{variant_id => {"quantity" => 1, "se_numbers" => Array, "iu_ids" => Array}
    #{ret => retHash, skip => ?}
    def group_sold_inventory_units_more_details(shipment, pending_iu_ids)
      retHash = Hash.new
      skip_count = 0;
      shipment.shipping_events.un_shipped.each do |event|
        event.inventory_units.each do |unit|
          if (unit.state == "sold")
            raise "duplicates happened for shipment #{shipment.number}" if pending_iu_ids.has_key?(unit.id) && pending_iu_ids[unit.id] != ExaltWarehouseState::RECEIVED && pending_iu_ids[unit.id] != ExaltWarehouseState::PENDING
            if pending_iu_ids.has_key?(unit.id)
              skip_count += 1;
              next
            end
            if retHash.has_key?(unit.variant_id)
              retHash[unit.variant_id]["quantity"] += 1
            else
              retHash[unit.variant_id] = {"quantity" => 1, "se_numbers" => Array.new, "iu_ids" => Array.new};
            end
            retHash[unit.variant_id]["se_numbers"].push(event.number)
            retHash[unit.variant_id]["iu_ids"].push(unit.id)
          end
        end       
      end
      
      # sort the se numbers and ius
      retHash.each_pair do |variant_id, value|
        value["se_numbers"] = value["se_numbers"].sort if !value["se_numbers"].nil?
        value["iu_ids"] = value["iu_ids"].sort if !value["iu_ids"].nil?
      end
      return { :ret => retHash, :skip_count => skip_count}      
    end

    # return s3 url
    def export_to_csv(start_from, end_at)
      filename = "exalt-shipments-"+Time.now.strftime("%Y%m%d%H%M%S")
      file = Tempfile.new( ["filename", '.csv'] )
      
      shipment_data = ShipmentCommonFunction::build_shipment_data(start_from, end_at, false)

      skip_count = 0
      CSV.open(file.path(), "wb") do |csv|
        csv << HEADER
        shipment_data["display_hash"].each_pair do |order_id, value|
          order = value["order"]
          skip_count += generate_per_order(csv, order, value)          
        end        
      end
      
      puts "Total products skipped: #{skip_count.to_s}"      
      som = Spree::ShippingOutputManifest.new
      som.avatar_file_name = "a.txt"
      som.avatar_content_type = "text/plain"
      som.avatar = file
      som.save
      file.delete()
      
      return som.avatar.url
    end    
    
    
    def generate_per_order(csv, order, value)            
      # reference2 = ""
      # reference3 = ""
      name = order.ship_address.full_name      
      company = ""  
      address1 = order.ship_address.address1
      address2 = order.ship_address.address2

      puts "address1 is more than 50: " + order.number.to_s if address1.length > 50
      puts "address2 is more than 50: " + order.number.to_s if address2.length > 50
      
      suburb = order.ship_address.city
      state = order.ship_address.state_text
      postcode = order.ship_address.zipcode
      country = ""
      phone = order.ship_address.phone
      email = order.user.email
      
      customer_instructions = "Thank you for your order"
      warehouse_instructions = ""
      freight_instructions = ""
      
      supplier_code = ""
      carrier_service_code = ""
      is_alt_required = ""
      
      raise "We don't support mulitple shipments per order now!: " + order.number.to_s if order.shipments.count > 1
      
      s = order.shipments.first
      source1 = s.group_sold_inventory_units
      quantity_hash = value["preview_object"].get_categorized_inventory["sold"];
    
      raise "validate products amount failed!:" + order.number + "[#{source1.size.to_s} =? #{value["preview_object"].get_categorized_inventory["sold"].size.to_s}]" if (source1.size != value["preview_object"].get_categorized_inventory["sold"].size)
      
      i_count = 0
      skip_count = 0
      
      grouped_ui = Array.new
      pending_iu_ids = ExaltWarehouseState.get_inventory_units_id_list(order)

      skip_count = 0;
      tmp_hash = group_sold_inventory_units_more_details(s, pending_iu_ids)
      skip_count +=  tmp_hash[:skip_count]



      if skip_count == order.inventory_units.size && tmp_hash[:ret].size > 0
        puts "Order #{order.number} has been received by warehouse"
        return skip_count
      end
      
      # if tmp_hash[:ret].size == 0
      #   backorder_count = 0
      #   order.inventory_units.each do |iu|
      #     backorder_count += 1 if iu.state == "backordered"
      #   end
      #   if (backorder_count + skip_count) ==  order.inventory_units.size
      #     puts "Order #{order.number} has been received by warehouse"
      #     return skip_count
      #   else
      #     puts "backorder: #{backorder_count}, skip: #{skip_count}, total: #{order.inventory_units.size}"
      #     raise "Order #{order.number} some product has been double shipped or missed"
      #   end
      # end 
       
              
      tmp_hash[:ret].each_pair do |variant_id, value|
        value["iu_ids"].each do |iu_id|
          raise "inventory id is not unique #{order.number}" if grouped_ui.include?(iu_id)
          grouped_ui.push(iu_id);
        end
      end
            
      grouped_ui = grouped_ui.sort # sort inventroy id.
      reference1 = order.number + "[" + Spree::LongStringMap.transfer(grouped_ui.join("-").to_s,38) + "]"
      

      tmp_hash[:ret].each_pair do |variant_id, value|
        variant = Spree::Variant.find variant_id
        quantity = value["quantity"]
        raise "quntity, se size and iu size are not matched!! #{order.number}" if value["se_numbers"].size != quantity || value["iu_ids"].size != quantity
        reference2 = Spree::LongStringMap.transfer(value["se_numbers"].join("-").to_s, 50)
        reference3 = Spree::LongStringMap.transfer(value["iu_ids"].join("-").to_s, 50)
        product_code = variant.sku
        raise "sku can not be empty" if product_code.blank?
        raise "sku can not longer than 20" if product_code.size > 20
        raise "validate varint quantity failed!:" + order.number + ", Variant: " + variant.id.to_s if (source1[variant.id]["quantity"] != quantity)
        description = variant.name_with_options_text              
        product_type = ""
        image_url = variant.get_aviable_first_image
        if image_url.blank?
          image_link = ""
        else
          image_link = image_url
        end
        # if variant.images.first.blank?
        #   image_link = ""
        # else 
        #   image_link =variant.images.first.attachment.url(:large)
        # end
        csv << [reference1, reference2, reference3, name, company, address1, address2, suburb, state, postcode, country, phone, email, customer_instructions, warehouse_instructions, freight_instructions, product_code, quantity, description, product_type, image_link, supplier_code, carrier_service_code, is_alt_required]
        i_count += quantity              
      end
      
      # s.shipping_events.each do |se|
      #   if !se.is_shipped? && !se.has_backordered_inventory?
      #     raise "We don't support mulitple inventory units per shipping event currently: order[#{order.number}]" + se.number.to_s if se.inventory_units.size > 1 
      #     iu = se.inventory_units.first
      #     raise "shipping events and inventory unit states are not matched!: " + se.number.to_s if iu.state != "sold"
      #     reference2 = se.number
      #     reference3 = iu.id              
      #     product_code = iu.variant.sku
      #     raise "sku can not be empty" if product_code.blank?
      #     raise "sku can not longer than 20" if product_code.size > 20
      #     quantity =  quantity_hash[iu.variant.id]
      #     raise "validate varint quantity failed!:" + order.number + ", Variant: " + iu.variant.id.to_s if (source1[iu.variant.id]["quantity"] != quantity)
      #     description = iu.variant.name_with_options_text              
      #     product_type = ""
      #     if iu.variant.images.first.blank?
      #       image_link = ""
      #     else 
      #       image_link =iu.variant.images.first.attachment.url(:large)
      #     end
      #     csv << [reference1, reference2, reference3, name, company, address1, address2, suburb, state, postcode, country, phone, email, customer_instructions, warehouse_instructions, freight_instructions, product_code, quantity, description, product_type, image_link, supplier_code, carrier_service_code, is_alt_required]
      #     i_count += quantity              
      #   end                         
      # end
                       
      i_count1 = 0
      order.inventory_units.each do |unit|
        if unit.state == "sold"
          i_count1 += 1
        end            
      end
      
      
      # puts i_count
      # puts i_count1
      raise "shipping event and inverntory unit are not matched #{order.number.to_s}" if i_count != (i_count1 - skip_count)
      return skip_count     
    end
    
    
    def parse(url, limit)
      ret = Array.new
      icount = 0;
      ret_hash = {:valid => true, :manifest_lines => Array.new}

      order_count = 0
      
      line_no = 1
      CSV.new(open(url), :headers => :first_row).each do |line|
        line_no += 1;        
        break if (line_no - 1) > limit.to_i 
        sml = Spree::ManifestLineExalt.new(line, line_no, self)
        ret_hash[:manifest_lines].push sml      
        ret_hash[:valid] = false if !sml.valid  
     end
     
     return ret_hash      
    end
    
    #validate the input manifest    
    def validate_manifext(manifest_id, limit, print)
      sm = Spree::ShipmentManifest.find manifest_id
      raise "Can not find manifest for id #{id}" if sm.blank?
            
      puts sm.avatar.url
      
      ret_hash = parse(sm.avatar.url, limit)
      
      error_count = 0;
      skip_count = 0;
      processed_count = 0;
      warning_count = 0;
      pass_count = 0;
      ret_hash[:manifest_lines].each do |line|
        line.println if print
        if !line.valid
          error_count += 1
        elsif line.skip
          skip_count += 1;
        elsif line.already_processed          
          processed_count += 1;
        elsif line.warning
          warning_count += 1;
        else
          pass_count += 1;          
        end                   
      end
      
      puts "\n"
      puts "\n"
      
      if ret_hash[:valid]
        puts "Valid: True"
      else
        puts "Valid: False"
      end
      puts "Total: #{ret_hash[:manifest_lines].size}, Error: #{error_count}, Manual Skip: #{skip_count}, Already Processd: #{processed_count}, Warning: #{warning_count}, Pass: #{pass_count}"
      return ret_hash
    end
    
    def process(ret_hash,skip_mail, only_send_to_backorder)
      total_count = 0;   
      valid_failed_count = 0;  #4
      state_error = 0;  #3
      already_process = 0;  #2
      processed_count = 0 #0
      skip_count = 0 # 1
      email_sent_count = 0;


      ret_hash[:manifest_lines].each do |line|
        line.process(skip_mail, only_send_to_backorder);
        line.process_println
        email_sent_count += 1 if line.mail_send
        total_count += 1
        case line.process_state
        when 1 
          skip_count += 1
        when 2
          already_process += 1
        when 3
          state_error += 1
        when 4 
          valid_failed_count += 1
        when 0
          processed_count += 1
        end
      end
      
      puts "Total: #{total_count}, Processed: #{processed_count}, Valid Failed: #{valid_failed_count}, Manually Skip: #{skip_count}, Already Processed: #{already_process}, State Error: #{state_error}, Email sent: #{email_sent_count}"
    end    
    
    def self.parse_reference1(reference1)
        ret_hash = {:order_number => nil, :iu_ids => nil}
        reg = /(.*)\[(.*)\]/
        md = reg.match(reference1)
        
        # make sure it is match the format
        if (md.size != 3)
          @msg = "#{reference1} is not formated as order_number[inventory_unit_ids]"
          return ret_hash
        end
        ret_hash[:order_number] = md[1]
        ret_hash[:iu_ids] = md[2]
        return ret_hash
    end
    
  end   
end