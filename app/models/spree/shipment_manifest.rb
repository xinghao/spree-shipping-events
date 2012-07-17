require 'csv'
module Spree
    class ShipmentManifest < ActiveRecord::Base
      attr_accessible :avatar
      attr_accessor :valid
      
      
    paperclip_opts = {
      :content_type => { :content_type => "text/csv" },
      :url => '/spree/admin/shipment-manifest/:id/:basename.:extension',
      :path => ':rails_root/public/spree/shipment-manifest/:id/:basename.:extension',
      :s3_headers => lambda { |attachment|
                           { "Content-Type" => "text/csv" }
                           }
      
    }
    
    unless Rails.env.development?
      paperclip_opts.merge! :storage        => :s3,
                            :s3_credentials => "#{Rails.root}/config/s3.yml",
                            :path           => 'app/public/spree/shipment-manifest/:id/:basename.:extension',                           
    end

      
    has_attached_file :avatar, paperclip_opts
    

    
    
    def parse()
      if Rails.env.development?
        url = self.avatar.path
      else
        url = self.avatar.url
      end
      
      ret = Array.new
      icount = 0;
      @valid = true
      CSV.new(open(url), :headers => :first_row).each do |line|
        icount += 1;
        sml = Spree::ManifestLine.new(line, icount, self)
        ret.push sml      
        @valid = false if !sml.valid  
     end
     
     return ret

    end
  end
end