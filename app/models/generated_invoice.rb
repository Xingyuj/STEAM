class GeneratedInvoice < ActiveRecord::Base
	acts_as :invoice

	# Overwrite constructor initialize
	# Calling generateConcreteCharges to generate concrete charges and column "total" for generated invoice
	# === Inputs attributes
	# => Reset id to nil as param attributes passed in contains this column, id in attributes belongs to ImportedInvoice
	#
	# Author: Xingyu Ji
	# === Preconditions
	# attributes permits "id" "start_date" "end_date" "issue_date" "distribution_loss_factor" "marginal_loss_factor" "retail_plan_id"
	# other columns should not be include in attributes such as "file, total, actable_id and actable_type"
	# "id" in attibutes is supposed to be the corresponding imported_invoice's id. and this id will be earsed after generateConcreteCharges
	# === Outputs
	# => generated_invoice with concrete_charges specified in correspeonding retail_plan
	def initialize attributes
		temp = attributes["id"]
		attributes.delete("id")
		super
		self.id = temp
		self.total = 0
		self.imported_invoice_id = temp
		generateConcreteCharges
		self.id = nil
	end

  # private function generateConcreteCharges
  # Called in constructor to generate concrete charges and column "total" for generated invoice
  # This function will generate concrete charges only appeared in retail_plan
	def generateConcreteCharges
	    #For each charge factories asscociated with retail plans, generate concrete charge and total them
	    self.retail_plan.charge_factories.each do |charge_factory| 
	      generated_concrete_charges = charge_factory.specific.concreteCharge(self)
	      #Put each generated_concrete_charge to GeneratedInvoice
	      generated_concrete_charges.each do |generated_concrete_charge|	      	
		      self.concrete_charges << generated_concrete_charge
		      self.total += generated_concrete_charge.amount
	      end
	    end
	end

	#Get the usage data from metering system for a specfic time period
	#Return the usage data
	def self.usage(start_date, end_date, daily_usage_period, meters)
	    usages=[]
	    daily_usage_period.each do |time_period|
	      start_time = time_period[:start_time]
	      end_time = time_period[:end_time]
	      sum = Meter.usage(start_date, end_date, start_time, end_time, meters)
	      usages.push sum
	    end
	    return usages
	end
	private :generateConcreteCharges
end
