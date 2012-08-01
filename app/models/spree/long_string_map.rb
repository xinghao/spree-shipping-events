module Spree
  class LongStringMap < ActiveRecord::Base
    
     before_create :generate_string_number
    
    private
    def generate_string_number
      return self.number unless self.number.blank?
      record = true
      while record
        random = "LSM#{Array.new(11){rand(9)}.join}"
        record = self.class.where(:number => random).first
      end
      self.number = random
    end
    
  end
end
