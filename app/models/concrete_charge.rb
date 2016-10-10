class ConcreteCharge < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :charge_factory

  #Store the specific information of the invoice into a hash table called charge_attributes
  def store_attributes name, meters, rate, cost, uom, usage, confidence, invoice_rate, days=nil
    hash = {}
    if !name.blank?
      hash[:name] = name
    end
    if !meters.blank?
      hash[:meters] = meters
    end
    if !rate.blank?
      if(rate.class.eql?(String) && rate[0].eql?('$'))
        rate = rate[1...rate.size]
      end
      hash[:rate] = rate.to_f
    end
    if !cost.blank?
      hash[:cost] = cost
    end
    if !uom.blank?
      hash[:uom] = uom
    end
    if !usage.blank?
      hash[:usage] = usage
    end  
    if !confidence.blank?
      hash[:confidence] = confidence
    end  
    if !invoice_rate.blank?
      hash[:invoice_rate] = invoice_rate
    end 
    if !days.blank?
      hash[:days] = days
    end
    self.charge_attributes = hash
  end
end
