# created and modified by Charlene

class ChargeFactory < ActiveRecord::Base
  actable
  belongs_to :retail_plan
  has_many :concrete_charges, dependent: :destroy

  #Abstract method to be implemented in specific subclass
  def concreteCharge invoice
    raise "inside ChargeFactory's concreteCharge method"
  end

  def import_concrete_charge invoice, amount
	  imported_concrete_charge = ConcreteCharge.new
    imported_concrete_charge.amount = amount
    imported_concrete_charge.invoice_type = "ImportedInvoice"
    self.concrete_charges << imported_concrete_charge
    invoice.concrete_charges << imported_concrete_charge
    return imported_concrete_charge
  end

  # Set and return the Charge types in a charge factory
  def self.charge_types
  	charge_types = []
  	ChargeFactory.all.each do |charge_factory|
  		charge_types << charge_factory.name.downcase unless charge_types.include? charge_factory.name
    end     
  	return charge_types
  end
end
