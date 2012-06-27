Spree::Admin::ShipmentsController.class_eval do

 after_filter :update_shipment_state, :only => [:update]
  
  def update_shipment_state

    if @shipment.all_shipped? && @shipment.state != "shipped"
       

      #@shipment.inventory_units.each &:ship!
      #if @shipment.send("ship")
      @shipment.state = "shipped"
      @shipment.update!(@shipment.order)  
    end  

  end
  
  # def update_shipping_events
  #   Rails.logger.info("RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR")
  #   shipping_events_attribute = params["shipment"]["shipping_events_attributes"]
  #   shipping_events_attribute.each_pair do |key,value|
  #     Rails.logger.info("RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR: " + value.to_s)
  #     if (!value["tracking"].nil? && value["tracking"] != "")
  #       se = ShippingEvent.find(value["id"])
  #       se.tracking = value["tracking"]
  #       Rails.logger.info("RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR2: " + se.tracking)
  #       se.save         
  #     end
  #   end      
  # end
  
  
  def fire
    if @shipment.partial_shipped?
       @shipment.send_shipment_mail
       flash.notice = "Mail has been sent"
    else
       flash[:error] = "Can not send shipping mail without any shipping events!" 
    end
    respond_with(@shipment) { |format| format.html { redirect_to :back } }
  end
  
  
end
