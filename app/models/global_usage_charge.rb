class GlobalUsageCharge < ActiveRecord::Base
  acts_as :charge_factory
  
  # concreteCharge override method of Chargefactory
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
  # concrete charges that created through this function will be add to current ChargeFactory (GlobalUsageCharge)
  # and return the concrete charges
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
    #Set date_range daily_time_period meters
    date_range = []
    daily_time_period = []
    meter = []
    meters.each do |meter_of_the_billingsite|
      meter << meter_of_the_billingsite[:serial]
    end
    date_range << {start_date: invoice.start_date, end_date: invoice.end_date}

    #Determine which meter usage to call, if end_date is greater than today, call predict meter method
    if invoice.instance_of? PredictedInvoice
      concrete_charge.invoice_type = "PredictedInvoice"
      global_usage = Meter.predicted_usage_by_meter(date_range, daily_time_period, meters.to_a)
    elsif invoice.instance_of? GeneratedInvoice     
      concrete_charge.invoice_type = "GeneratedInvoice"
      global_usage = Meter.usage_by_meter(date_range, daily_time_period, meters.to_a)
    end
    if global_usage.instance_of?(Hash) and global_usage.keys.include? :errors
      logger.debug "Errors raised: " + global_usage[:errors].to_s
    else
      usage_temp = 0
      if !global_usage.first[:usage].nil?
        usage_temp = global_usage.first[:usage]
      end
      concrete_charge.amount = usage_temp * rate * (1+total_loss_factor)
    end
    concrete_charge.charge_factory_id = self.acting_as.id
    concrete_charges << concrete_charge
    current_concrete_charges << concrete_charge
    concrete_charge.store_attributes self.name, meter, rate.to_f, concrete_charge.amount.to_f, self.unit_of_measurement, usage_temp, global_usage.first[:confidence], nil
    return current_concrete_charges
  end
end
