class PredictedInvoice < ActiveRecord::Base
  acts_as :invoice

  #Reload constructor initialize
  #Calling generateConcreteCharges to generate concrete charges and column "total" for generated invoice
  #Reset id to nil as param attributes passed in contains this column
  #@parm attributes 
	def initialize attributes
		super
		self.actable_type = "PredictedInvoice"
		self.total = 0
		generateConcreteCharges
		self.id = nil
	end


  #private function generateConcreteCharges
  #Called in constructor to generate concrete charges and column "total" for generated invoice 
	def generateConcreteCharges
		#For each charge factories asscociated with retail plans, generate concrete charge and total them
	    self.retail_plan.charge_factories.each do |charge_factory| 
	      predicted_concrete_charges = charge_factory.specific.concreteCharge(self)
	      #Put each generated_concrete_charge to PredictedInvoice
	      predicted_concrete_charges.each do |predicted_concrete_charge|
		      self.concrete_charges << predicted_concrete_charge
		      self.total += predicted_concrete_charge.amount
	      end
	    end
	end

  #Get the usage data from metering system for a specfic time period
  #Return the usage data
	def self.usage(start_date, end_date, daily_usage_period, meters)
	    usages = []
      daily_usage_period.each do |time_period|
        sum = LinearRegressionPredictor.usage_by_meter(start_date, end_date, time_period, meters)
        usages.push sum
      end
	end

	private :generateConcreteCharges
end
