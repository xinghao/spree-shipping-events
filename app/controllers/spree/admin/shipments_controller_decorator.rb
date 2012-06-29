Spree::Admin::ShipmentsController.class_eval do

 after_filter :update_shipment_state, :only => [:update]
  
  def update_shipment_state

    if @shipment.all_shipped? && @shipment.state != "shipped"
       

      #@shipment.inventory_units.each &:ship!
      #if @shipment.send("ship")
  
      @shipment.state = "shipped"
      @shipment.update!(@shipment.order)
      @shipment.order.shipment_state = @shipment.state
      @shipment.order.save   
    end  

  end
    
  
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
