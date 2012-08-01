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
                            :path           => 'app/public/spree/shipment-manifest/:id/:basename.:extension'                           
    end

      
    has_attached_file :avatar, paperclip_opts
    

    def skip_email?()
      return self.avatar_file_name.match(/^skip_email/i)
    end
    
    def parse()
      if Rails.env.development?
        url = self.avatar.path
      else
        url = self.avatar.url
      end
      
      ret = Array.new
      icount = 0;
      @valid = true
      order_count = 0
      integrate_line = nil
      CSV.new(open(url), :headers => :first_row).each do |line|
        icount += 1;
        if icount % 2  == 1
          raise "CSV file Error: line #{icount + 1} does not start with C" if (line[0].strip.downcase != "c")
          integrate_line = Hash.new
          integrate_line[Spree::ManifestLine::TRACKING_NUMBER] = line[1]
          integrate_line[Spree::ManifestLine::DELIVERY_INSTRUCTION] = line[18]          
          next
        else
          order_count += 1
          raise "CSV file Error: line #{icount + 1} does not start with M" if (line[0].strip.downcase != "a")
          integrate_line[Spree::ManifestLine::PRODUCT_DESCRIPTION] = line[6]
        end
        
        sml = Spree::ManifestLine.new(integrate_line, order_count, self)
        ret.push sml      
        @valid = false if !sml.valid  
     end
     
     return ret

    end
  end
end