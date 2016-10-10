class ImportedInvoice < ActiveRecord::Base
  acts_as :invoice

  # initialize an imported invoice
  def initialize(retail_plan, file)
    super()
    self.importCSV(retail_plan, file)
  end

  # Store the imported invoice in specified directory
  def store_file(file)
    name = file.original_filename
    directory = "/home"
    @path = File.join(directory, name)
    File.open(path, "wb") { |f| f.write(file.read) }
  end

  # Specify the invoice directory
  def invoice_directory
    @path
  end 

  # Importing of an Invoice
  # Looks for and saves every charge in the uploaded invoice
  def importCSV(retail_plan, file)

    # Using Dynamic usage_charge_types get from ChargeFactory.charge_types.
    # Downside is may loss concrete_charge from real invoice csv file, if the charge name of csv cant be found in retail plan
    @usage_charge_types = ChargeFactory.charge_types

    self.file = file.original_filename
    self.retail_plan_id = retail_plan.id
    meters = []
    perMeterFlag = true
    uom = nil
    CSV.foreach(file.path) do |content|
      self.start_date = content[1] if content[0]!= nil && content[0].downcase == "start date" 
      self.end_date = content[1] if content[0]!= nil && content[0].downcase == "end date" 
      self.distribution_loss_factor = content[1].to_f/100 if content[0]!= nil && content[0].downcase == "distribution loss factor"
      self.marginal_loss_factor = content[1].to_f/100 if content[0]!= nil && content[0].downcase == "marginal loss factor"
      uom = content[1] if !content.blank? && content[0]!= nil && content[0].downcase == "unit of measurement" && !content[1].blank?
      meters.push(content[1]) if content[0]!= nil && content[0].downcase == "meter identifier"
      perMeterFlag = false if content[0]!= nil && content[0].downcase == "maximum demand"
      self.total = content[3] if content[0] == nil && content[1] == nil && content[2] == nil && content[3]!=nil
      
      if(!content.blank? && content[0]!=nil && content[0].downcase.in?(@usage_charge_types))
        charge_factory = retail_plan.charge_factories.where("lower(name) = ?", content[0].downcase).take
        invoice_rate = nil

        #call import_concrete_charge in charge_factory to import concrete charges
        concrete_charge = charge_factory.import_concrete_charge self, content[3]
        if content[2]!=nil
          invoice_rate = content[2] if content[0] == "SREC Charge" || content[0] == "LRET Charge" || content[0] == "ESC Charge"
          if !invoice_rate.nil? && !invoice_rate.index('%').nil?          
            invoice_rate = invoice_rate.to_f/100
          end
        end
        if perMeterFlag
          concrete_charge.store_attributes content[0], meters.last, content[2], content[3], uom, content[1], nil, invoice_rate
        elsif content[0] == "Supply Charge"
          concrete_charge.store_attributes content[0], meters, content[2], content[3], uom, nil, nil, invoice_rate, content[1]
        else
          concrete_charge.store_attributes content[0], meters, content[2], content[3], uom, content[1], nil, invoice_rate
        end
      end
    end
    
    return self
  end

end
