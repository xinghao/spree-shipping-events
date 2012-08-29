module Spree
  module Admin 
    class ShipmentManifestsController < Spree::Admin::BaseController
      
      def new
        @shipment_manifest = ShipmentManifest.create( params[:shipment_manifest] )
      end
      
      def commit
        @shipment_manifest = ShipmentManifest.find( params[:id] )
        @lines = @shipment_manifest.parse
        if !@shipment_manifest.valid
          flash.notice = "Validation failed! Please correct the manifest before click the process button."
          render "validate"
          return
        end
        @lines.each do |line|
          line.process
        end
      end
      
      def update
        @shipment_manifest = ShipmentManifest.find(params[:id])
        @shipment_manifest.uploaded_at = Time.now
        if @shipment_manifest.update_attributes(params[:shipment_manifest])
          flash.notice = flash_message_for(@shipment_manifest, :successfully_updated)
          #@lines = @shipment_manifest.parse 
          #render "validate"
          render "uploaded"
        else
          flash.notice = "upload failed! please contact support"
          render "upload_failed"          
        end
      end
        
    end
  end
end
