class BillingSite < ActiveRecord::Base

  belongs_to :site
  has_many :meters, dependent: :destroy
  has_many :retail_plans, dependent: :destroy
  has_many :invoices, through: :retail_plans

  #Generate a new invoice based on the updated usage data
  def self.update_generated_invoice meters, date_ranges
    
    #find all metering_charges of imported invoice in the database
    #because the charge_attributes of metering_charge have a list of relevant meters 
    concrete_charge_metering = []
    ConcreteCharge.all.each do |temp|
      charge_attribute = eval temp[:charge_attributes]
      if charge_attribute[:name].eql?("Metering Charge") && temp[:invoice_type].eql?("ImportedInvoice")
      concrete_charge_metering.push temp
      end
    end

    if !concrete_charge_metering.empty?
      #find relevant metering_charge with the meters
      concrete_charge_result = []
      concrete_charge_metering.each do |mcharge|
        meter_array = eval mcharge[:charge_attributes]
        meter_array = meter_array[:meters]
        meters.each do |meter|
          if !concrete_charge_result.include?(mcharge) && meter_array.include?(meter[:serial])
          concrete_charge_result.push mcharge
          end
        end
      end
      
      if !concrete_charge_result.empty?
        #find imported invoice with date period
        imported_invoice_result = []
        concrete_charge_result.each do |ccharge|
          date_ranges.each do |date_period|
            imported_invoice_temp = Invoice.find(ccharge[:invoice_id])
            if !imported_invoice_result.include?(imported_invoice_temp) &&
              (date_period[:start_date]<imported_invoice_temp[:end_date]||
                imported_invoice_temp[:start_date]<date_period[:end_date])
              imported_invoice_result.push imported_invoice_temp
            end
          end
        end
        
        if !imported_invoice_result.empty?
        #update the generated invoice
        imported_invoice_result.each do |invoice|
          result = {}
          result["id"] = invoice[:actable_id]
          result["start_date"] = invoice[:start_date]
          result["end_date"] = invoice[:end_date]
          result["issue_date"] = invoice[:issue_date]
          result["distribution_loss_factor"] = invoice[:distribution_loss_factor]
          result["marginal_loss_factor"] = invoice[:marginal_loss_factor]
          result["total"] = invoice[:total]
          result["retail_plan_id"] = invoice[:retail_plan_id]
          new_generated_invoice = GeneratedInvoice.new(result)
          new_generated_invoice.save
        end
        else
          logger.debug "No relevant imported invoice in the system"
        end
      else
        logger.debug "No relevant metering charge in the system"
      end
    else
      logger.debug "No metering charge in the system"
    end
  end
end
