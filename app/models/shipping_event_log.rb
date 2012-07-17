class ShippingEventLog < ActiveRecord::Base
  belongs_to :shipping_event, :class_name => "ShippingEvent";
  belongs_to :shipment_manifest, :class_name => "Spree::ShipmentManifest";
end
