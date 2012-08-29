require 'csv'
module Spree
  class ShippingOutputManifest < ActiveRecord::Base
    attr_accessible :avatar

    paperclip_opts = {
      :content_type => { :content_type => "text/csv" },
      :url => '/spree/admin/shipping-output-manifest/:id/:basename.:extension',
      :path => ':rails_root/public/spree/shipping-output-manifest/:id/:basename.:extension',
      :s3_headers => lambda { |attachment|
                           { "Content-Type" => "text/csv" }
                           }
      
    }
    
    unless Rails.env.development?
      paperclip_opts.merge! :storage        => :s3,
                            :s3_credentials => "#{Rails.root}/config/s3.yml",
      #                      :s3_host_name => "s3-ap-southeast-1.amazonaws.com",
                            :path => 'app/public/spree/shipping-output-manifest/:id/:basename.:extension'                           
    end

      
    has_attached_file :avatar, paperclip_opts


  end
end
