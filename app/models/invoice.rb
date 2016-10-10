class Invoice < ActiveRecord::Base

	actable
	belongs_to :retail_plan
	has_many :concrete_charges, dependent: :destroy

	# Compare a real imported invoice with the associated generated invoice
	# 
	#
	# == Inputs
	# * +imported_invoice+ - an Invoice object
	# * +generated_invoice+ - an Invoice object
	# 
	# == Outputs
	# * +differences+ - an array
	def self.compareInvoices(imported_invoice, generated_invoice)

		differences = {}
		result = {}

		imported_charges = imported_invoice.portable_format
		generated_charges = generated_invoice.portable_format

		result[:imported] = imported_charges
		result[:generated] = generated_charges


		# imported invoice
		result[:imported][:concrete_charges][:daily_charges].each do |meter, charge|
			differences[meter] = {}
			charge.each do |value|
				temp_name = value[:name].downcase
				differences[meter][temp_name] = value[:cost].to_f
			end
		end 
		result[:imported][:concrete_charges][:global_charges].each do |value|
			temp_name = value[:name].downcase
			temp_value = differences[temp_name]
			differences[temp_name] = value[:cost].to_f
		end
		result[:imported][:concrete_charges][:supply_charges].each do |value|
			temp_name = value[:name].downcase
			temp_value = differences[temp_name]
			differences[temp_name] = value[:cost].to_f
		end
		result[:imported][:concrete_charges][:metering_charges].each do |value|
			temp_name = value[:name].downcase
			temp_value = differences[temp_name]
			differences[temp_name] = value[:cost].to_f
		end
		result[:imported][:concrete_charges][:certificate_charges].each do |value|
			temp_name = value[:name].downcase
			temp_value = differences[temp_name]
			differences[temp_name] = value[:cost].to_f
		end
		result[:imported][:concrete_charges][:capacity_charges].each do |value|
			temp_name = value[:name].downcase
			temp_value = differences[temp_name]
			differences[temp_name] = value[:cost].to_f
		end
		differences[:total] = result[:imported][:total_charges]
		# imported invoice end

		# generated invoice
		result[:generated][:concrete_charges][:daily_charges].each do |meter, info|
			if differences[meter]
				info.each do |value|
					temp_name = value[:name].downcase
					temp_value = differences[meter][temp_name]
					if temp_value == 0 && value[:cost].to_f == 0
						differences[meter][temp_name] = 0.00
					elsif temp_value == 0 || value[:cost].to_f == 0
						differences[meter][temp_name] = 100.00
					else
						divider = value[:cost].to_f >= temp_value ? value[:cost].to_f : temp_value
						differences[meter][temp_name] = ((value[:cost].to_f - temp_value).abs / divider) * 100
					end
				end
			end
		end
		result[:generated][:concrete_charges][:global_charges].each do |value|
			temp_name = value[:name].downcase
			temp_value = differences[temp_name]
			if temp_value == 0 && value[:cost].to_f == 0
				differences[temp_name] = 0.00
			elsif temp_value == 0 || value[:cost].to_f == 0
				differences[temp_name] = 100.00
			else
				divider = value[:cost].to_f >= temp_value ? value[:cost].to_f : temp_value
				differences[temp_name] = ((value[:cost].to_f - temp_value).abs / divider) * 100
			end
		end
		result[:generated][:concrete_charges][:supply_charges].each do |value|
			temp_name = value[:name].downcase
			if differences[temp_name]
				temp_value = differences[temp_name]
				if temp_value == 0 && value[:cost].to_f == 0
					differences[temp_name] = 0.00
				elsif temp_value == 0 || value[:cost].to_f == 0
					differences[temp_name] = 100.00
				else
					divider = value[:cost].to_f >= temp_value ? value[:cost].to_f : temp_value
					differences[temp_name] = ((value[:cost].to_f - temp_value).abs / divider) * 100
				end
			end
		end
		result[:generated][:concrete_charges][:metering_charges].each do |value|
			temp_name = value[:name].downcase
			temp_value = differences[temp_name]
			if temp_value == 0 && value[:cost].to_f == 0
				differences[temp_name] = 0.00
			elsif temp_value == 0 || value[:cost].to_f == 0
				differences[temp_name] = 100.00
			else
				divider = value[:cost].to_f >= temp_value ? value[:cost].to_f : temp_value
				differences[temp_name] = ((value[:cost].to_f - temp_value).abs / divider) * 100
			end
		end
		result[:generated][:concrete_charges][:certificate_charges].each do |value|
			temp_name = value[:name].downcase
			temp_value = differences[temp_name]
			if temp_value == 0 && value[:cost].to_f == 0
				differences[temp_name] = 0.00
			elsif temp_value == 0 || value[:cost].to_f == 0
				differences[temp_name] = 100.00
			else
				divider = value[:cost].to_f >= temp_value ? value[:cost].to_f : temp_value
				differences[temp_name] = ((value[:cost].to_f - temp_value).abs / divider) * 100
			end
		end
		result[:generated][:concrete_charges][:capacity_charges].each do |value|
			temp_name = value[:name].downcase
			temp_value = differences[temp_name]
			if temp_value == 0 && value[:cost].to_f == 0
				differences[temp_name] = 0.00
			elsif temp_value == 0 || value[:cost].to_f == 0
				differences[temp_name] = 100.00
			else
				divider = value[:cost].to_f >= temp_value ? value[:cost].to_f : temp_value
				differences[temp_name] = ((value[:cost].to_f - temp_value).abs / divider) * 100
			end
		end
		total_value = differences[:total]
		if total_value == 0 && result[:generated][:total_charges].to_f == 0
			differences[:total] = 0.00
		elsif total_value == 0 || result[:generated][:total_charges].to_f == 0
			differences[:total] = 100.00
		else
			divider = result[:generated][:total_charges] >= total_value ? result[:generated][:total_charges] : total_value
			differences[:total] = ((result[:generated][:total_charges] - total_value).abs / divider) * 100
		end
		# generated invoice end


		return result, differences

	end

	# This method is used to return portable data, which describes some attribute of an Invoice
	# 
	#
	# == Outputs
	# Returns a hash value with all concrete_charges
	def portable_format
		
		# an invoice basic information
		invoice_hash = {}
		invoice_hash[:id] = self.id
		invoice_hash[:start_date] = self.start_date
		invoice_hash[:end_date] = self.end_date
		invoice_hash[:issue_date] = self.issue_date
		invoice_hash[:total_charges] = self.total
		invoice_hash[:distribution_loss_factor] = self.distribution_loss_factor
		invoice_hash[:marginal_loss_factor] = self.marginal_loss_factor
		invoice_hash[:total_loss_factor] = self.distribution_loss_factor + self.marginal_loss_factor
		invoice_hash[:discount] = self.retail_plan.discount
		invoice_hash[:generated_at] = self.created_at


		# all concrete charges of an invoice 
		daily_charges = []
		global_charges = []
		supply_charges = []
		metering_charges = []
		capacity_charges = []
		certificate_charges = []
		all_concrete_charges = ConcreteCharge.where("invoice_id = ?", self.id)
		all_concrete_charges.each do |item|
			if item.charge_factory.specific.is_a?(DailyUsageCharge)
				daily_charges << eval(item.charge_attributes)	# string to hash
			elsif item.charge_factory.specific.is_a?(GlobalUsageCharge)
				global_charges << eval(item.charge_attributes)	# string to hash
			elsif item.charge_factory.specific.is_a?(SupplyCharge)
				supply_charges << eval(item.charge_attributes)	# string to hash
			elsif item.charge_factory.specific.is_a?(MeteringCharge)
				metering_charges << eval(item.charge_attributes)	# string to hash
			elsif item.charge_factory.specific.is_a?(CapacityCharge)
				capacity_charges << eval(item.charge_attributes)	# string to hash
			else
				certificate_charges << eval(item.charge_attributes)		# string to hash
			end
		end

		meters_in_dailycharges = []		
		daily_charges.each do |daily|
			meters_in_dailycharges << daily[:meters]
		end
		meters_in_dailycharges.uniq!	# uniq meters occur in daily charges

		daily_bymeter= {}
		meters_in_dailycharges.each do |meter|
			daily_bymeter[meter] = []
			daily_charges.each do |daily|
				if daily[:meters] == meter
					daily_bymeter[meter] << daily
				end
			end 
		end

		concrete_charges = {daily_charges: daily_bymeter, global_charges: global_charges,
							supply_charges: supply_charges, metering_charges: metering_charges,
							capacity_charges: capacity_charges, certificate_charges: certificate_charges}

		invoice_hash[:concrete_charges] = concrete_charges


		return invoice_hash

	end

  ##
  #
  # Get the list of predicted invoice
  #
  # ==== Attributes
  #
  # * +billing_site_id+ - The billing site ID the invoice belonged to
  #
  def self.get_prediction_invoice billing_site_id
    predicted_invoices = []
    billing_site =BillingSite.find(billing_site_id)
    retail_plan = billing_site.retail_plans.last
    invoice = retail_plan.invoices.where(actable_type: ImportedInvoice).last
    @imported_invoice = invoice.specific
    # @file_name = ImportedInvoice.find(@imported_invoice.actable_id).file
    @predictable_billing_periods = retail_plan.predictable_billing_periods
    @predictable_billing_periods.each do |predictable_billing_period|
      #Based on the selection of imported invoice from the user
      attributes = Marshal.load( Marshal.dump(@imported_invoice.attributes))
      attributes["start_date"] = predictable_billing_period[:start_date]
      attributes["end_date"] = predictable_billing_period[:end_date]
      @predicted_invoice = PredictedInvoice.new(attributes.except!("file"))
      if @predicted_invoice.save
        logger.info "predicted_invoices for '"+@imported_invoice.specific.file+"' are successfully created"
        predicted_invoices << @predicted_invoice
      else
        logger.debug "predicted_invoices for '"+@imported_invoice.specific.file+"' fail to create"
      end
    end
    return predicted_invoices
  end

end
