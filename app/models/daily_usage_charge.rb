class DailyUsageCharge < ActiveRecord::Base

  acts_as :charge_factory

  # Function concreteCharge override method of Chargefactory
  # create concrete charges for PredictedInvoice and GeneratedInvoice.
  # return currently created concrete charges
  #
  # Author: Xingyu Ji
  #
  # ==== Inputs
  # * +invoice
  # parameter invoice is supposed to include attributes of a Generated or Predicted invoice except the id
  # id of paramater invoice is supposed to be the ImportedInvoice's id
  #
  # === Preconditions
  # Expects variables to be the correct type (see above)
  #
  # === Outputs
  # concrete charges that created through this function will be add to current ChargeFactory (DailyUsageCharge)
  # and return the concrete charges

  def concreteCharge(invoice)
    meters = []
    aims = ImportedInvoice.find(invoice[:id]).acting_as.concrete_charges
    aims.each do |aim|
      aim = eval aim[:charge_attributes]
      if aim[:name].eql?("Supply Charge")
        aim = aim[:meters]
        aim.each do |meter_temp|
          meters<<Meter.find_by(serial:meter_temp)
        end
      end
    end
    
    #get value from imported invoice
    distribution_loss_factor = invoice.distribution_loss_factor
    marginal_loss_factor = invoice.marginal_loss_factor
    total_loss_factor = distribution_loss_factor + marginal_loss_factor
    rate = self.rate.blank? ? 1 : self.rate

    current_concrete_charges = []
    meters.each do |meter|
      concrete_charge = ConcreteCharge.new
      
      #Set date_range daily_time_period
      date_range = []
      date_range << {start_date: invoice.start_date, end_date: invoice.end_date}
      daily_time_period = []
      daily_time_period << {start_time: self.start_time, end_time: self.end_time}

      #Determine which meter usage to call, if end_date is greater than today, call predict meter method
      if invoice.instance_of? PredictedInvoice
        daily_usage = meter.predicted_usage_by_meter(date_range, daily_time_period)
        concrete_charge.invoice_type = "PredictedInvoice"
      elsif invoice.instance_of? GeneratedInvoice
        daily_usage = meter.usage_by_meter(date_range, daily_time_period)
        concrete_charge.invoice_type = "GeneratedInvoice"
      end

      #calculate the charge amount taking into account the total loss factor
      usage_temp = 0
      if !daily_usage.first[:meters].empty?
        usage_temp = daily_usage.first[:meters].first[:daily_time_periods].first[:usage]
      end
      concrete_charge.amount = usage_temp * rate * (1 + total_loss_factor)
      concrete_charge.charge_factory_id = self.acting_as.id

      concrete_charges << concrete_charge
      current_concrete_charges << concrete_charge
      concrete_charge.store_attributes self.name, meter[:serial], self.rate.to_f, concrete_charge.amount.to_f, self.unit_of_measurement, usage_temp, daily_usage.first[:confidence], nil
    end
    return current_concrete_charges == nil ? nil : current_concrete_charges
  end
end
