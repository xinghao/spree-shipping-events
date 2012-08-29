module ShipInfo
  class BasicHandler
    def preview(start_from, end_at)
      return ShipmentCommonFunction::build_shipment_data(start_from, end_at, true)
    end
    
    # return s3 url
    def export(start_from, end_at)
    end
        
    def validate_manifext(url, limit)
    end    
  end
end