class SupplyCharge < ActiveRecord::Base

  acts_as :charge_factory

  # create concrete charges for PredictedInvoice and GeneratedInvoice.
  # return currently created concrete charges
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
    current_concrete_charges = []
    rate = self.rate.blank? ? 1 : self.rate
    concrete_charge = ConcreteCharge.new
    if invoice.instance_of? PredictedInvoice
      concrete_charge.invoice_type = "PredictedInvoice"
    elsif invoice.instance_of? GeneratedInvoice      
      concrete_charge.invoice_type = "GeneratedInvoice"
    end
    days = (invoice.end_date - invoice.start_date).to_i + 1
    concrete_charge.amount = days * rate.to_f
    concrete_charge.charge_factory_id = self.acting_as.id
    concrete_charges << concrete_charge
    current_concrete_charges << concrete_charge
    meter = []
    meters.each do |meter_of_the_billingsite|
      meter << meter_of_the_billingsite[:serial]
    end
    concrete_charge.store_attributes self.name, meter, rate.to_f, concrete_charge.amount.to_f, nil, nil, nil, nil,days 
    return current_concrete_charges
  end
end
