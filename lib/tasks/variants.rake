namespace :variants do
    desc "backorder certain variant but excaped certain amount"    
    task "backorder_valid", [:variant_id] => [:environment] do |t, args|
      variant_id = args[:variant_id].to_i
      variant = Spree::Variant.find variant_id
      if variant.blank?
        puts "Can not find this Variant for #{variant_id} !!!!!!!"
      end
      puts "Strat Validaate: Variant: #{variant.name_with_options_text}"
      if variant.valid_backorder
        puts "pass the validation"
      else
        puts "Validation failed"
      end      
    end
    
    
    desc "backorder certain variant but excaped certain amount"    
    task "backorder", [:variant_id, :except_number] => [:environment] do |t, args|
      #step 1: backorder the inventroy and shipmetn state order state
      variant_id = args[:variant_id].to_i
      except_number = args[:except_number]
      if except_number.blank?
        except_number = 0
      else
        except_number = except_number.to_i
      end
      variant = Spree::Variant.find variant_id
      if variant.blank?
        puts "Can not find this Variant for #{variant_id} !!!!!!!"
      end
      puts "Strat processing: Variant: #{variant.name_with_options_text}, skip: #{except_number}"
            
      if variant.valid_backorder
        variant.backorder(except_number)
      else
        puts "Validation failed"
      end      
            
      
      #step 2: updated on hand number
      variant.update_attributes_without_callbacks(:count_on_hand=> (0 - variant.on_backorder))
    end    
    
 end
