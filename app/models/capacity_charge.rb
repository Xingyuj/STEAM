class CapacityCharge < ActiveRecord::Base
  acts_as :charge_factory

  #Generate the concrete charge for capacity charge and maximum demand
  #Return the generated concrete charge
  def concreteCharge(invoice)
    meters = []
    aims = ImportedInvoice.find(invoice[:id]).acting_as.concrete_charges
    aims.each do |aim|
      aim = eval aim[:charge_attributes]
      if aim[:name].eql?("Metering Charge")
        aim = aim[:meters]
        aim.each do |meter_temp|
          meters<<Meter.find_by(serial:meter_temp)
        end
      end
    end
    distribution_loss_factor = invoice.distribution_loss_factor
    marginal_loss_factor = invoice.marginal_loss_factor
    total_loss_factor = distribution_loss_factor + marginal_loss_factor
    rate = self.rate.blank? ? 1 : self.rate
    current_concrete_charges = []
    concrete_charge = ConcreteCharge.new
    date_range = []
    daily_time_period = []
    meter = []
    meters.each do |meter_of_the_billingsite|
      meter << meter_of_the_billingsite[:serial]
    end
    if self.period== "billing_period" 
      date_range << {start_date: invoice.start_date, end_date: invoice.end_date}
    elsif self.period == "year"
      date_range << {start_date: invoice.end_date-1.year, end_date: invoice.end_date}
    else
      raise "Period type not supported"
    end

    #Determine which meter usage to call, if end_date is greater than today, call predict meter method
    if invoice.instance_of? PredictedInvoice
      concrete_charge.invoice_type = "PredictedInvoice"
      maximum_demand = Meter.predicted_usage_by_meter(date_range, daily_time_period, meters.to_a)
    elsif invoice.instance_of? GeneratedInvoice      
      concrete_charge.invoice_type = "GeneratedInvoice"
      maximum_demand = Meter.usage_by_meter(date_range, daily_time_period, meters.to_a)
    end
    
    if maximum_demand.instance_of?(Hash) and maximum_demand.keys.include? :errors
      logger.debug "Errors raised: " + maximum_demand[:errors].to_s
    else
      usage_temp = 0
      if !maximum_demand.first[:maximum_demand].nil?
        usage_temp = maximum_demand.first[:maximum_demand]
      end
      concrete_charge.amount = usage_temp * rate * (1+total_loss_factor)
    end
    concrete_charge.charge_factory_id = self.acting_as.id
    concrete_charges << concrete_charge
    current_concrete_charges << concrete_charge
    concrete_charge.store_attributes self.name, meter, rate.to_f, concrete_charge.amount.to_f, self.unit_of_measurement, usage_temp, maximum_demand.first[:confidence], nil
    return current_concrete_charges
  end
end
