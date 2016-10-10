class InvoicesController < ApplicationController

  # Define the index for Invoices
  #
  # /invoices
  def index
    @invoices = Invoice.all
  end

  #invoices/:id
  def show
    @invoice = Invoice.find(params[:id])
  end

  # Define the destroy method of Invoices
  # Deletes selected invoice and returns to billing site
  def destroy
    @invoice = Invoice.find(params[:id])
    @retail_plan = RetailPlan.find(@invoice.retail_plan_id)
    billing_site_id = @retail_plan.billing_site_id
    @invoice.destroy
    redirect_to billing_site_url(billing_site_id), notice: 'Invoice has been destroyed successfully !'
  end

  # Import an invoice to the system
  # /invoices/new
  def import_invoice
    @retail_plans = RetailPlan.where(billing_site_id: params[:billing_site])
    if @retail_plans == nil
      redirect_to billing_site_url(params[:billing_site]), notice: 'Please Create Retail Plan first!'
      return
    end
  end


  # Create an Imported Invoice in the system.
  # Once Imported, the system proceeds to generate an invoice based on the uploaded one.
  #
  # /invoices/import
  def create_imported_invoice
    count = 0
    current_billing_site_id = params[:billing_site]
    current_meters = Meter.where("billing_site_id = #{current_billing_site_id}")
    meters= []

    invoiceBillingSiteId = 0
    metercount = 0
    @usage_charge_types = ChargeFactory.charge_types
    if !params[:invoice].blank?
      #Check if any file has been selected before clicking on import, else return a notice.
      if !params[:invoice][:file].blank?
        file = params[:invoice][:file]
        file_name = file.original_filename
        #the file with same file_name will not be imported
        if ImportedInvoice.find_by(file: file_name) != nil
          presentImportedInvoice = ImportedInvoice.find_by(file: file_name)
          presentInvoice = Invoice.where(actable_id: presentImportedInvoice.id, actable_type: "ImportedInvoice")
          presentRetailPlan = RetailPlan.find(presentInvoice.first.retail_plan_id)
          invoiceBillingSiteId = presentRetailPlan.billing_site_id
        end

        if invoiceBillingSiteId.to_s == current_billing_site_id
          redirect_to import_invoice_invoices_path(:billing_site => current_billing_site_id)
          flash[:error] = "The file to be imported is already existing, please select another file!"
          return
        else
          if !params[:invoice][:start_date].blank? || !params[:invoice][:end_date].blank? || !params[:invoice][:retail_plan_id].blank?
            if count == 0
              case File.extname(file_name)
                when ".csv"

                  #Adds the meter identifier data to temporary variable 'meters'
                  CSV.foreach(file.path) do |content|
                    meters.push(content[1]) if content[0]!= nil && content[0].downcase == "meter identifier"
                  end
                  #check if the meters in imported invoice match with the meters in the billing site
                  meters.each do |check|
                    current_meters.each do |cmeter|
                      if check == cmeter.serial
                        metercount += 1
                        #i+=1
                      end
                    end
                  end

                  #allow importing of invoice only if all meters match
                  if metercount == meters.length
                    retail_plan = RetailPlan.find(params[:invoice][:retail_plan_id])  #Get speciifc Retail plan, then import the retail plan data along with file and file_name.
                    @invoice = ImportedInvoice.new(retail_plan, file)
                    # @csv_file_store = @invoice.store_file(file,file_name) #do we need to store a ImportedInvoice in a file locally?
                    if @invoice.save

                      #after importing invoice, create new GeneratedInvoice
                      current_billing_site = BillingSite.find(retail_plan[:billing_site_id])
                      meter = Meter.where("billing_site_id = #{current_billing_site[:id]}")

                      #Prevent user from generating an invoice without meter data
                      if meter.blank?
                        flash[:error] = "Please generate at least one meter and try again"
                        @invoice.destroy
                        redirect_to "/billing_sites/#{current_billing_site[:id]}"
                      else
                        @generated_invoice = GeneratedInvoice.new(@invoice.attributes.except!("file"))
                        if @generated_invoice.save
                          logger.info "generated_invoices for '"+@invoice.file+"' are successfully created"
                        else
                          logger.debug "generated_invoices for '"+@invoice.file+"' fail to create"
                        end
                        bs_id = retail_plan.billing_site_id

                        redirect_to billing_site_url(bs_id), notice: 'Invoice was successfully imported.'
                        respond_to do |format|
                          format.json { render :show, status: :imported, location: @invoice }
                          return
                        end
                      end
                    else
                      respond_to do |format|
                        format.html { render :generateNew }
                        format.json { render json: @invoice.errors, status: :unprocessable_entity }
                        return
                      end
                    end
                  else
                    flash[:error] = "Meters#{meters} in imported invoice does not match with Billing Site's meters. Please check and try again"
                    redirect_to import_invoice_invoices_path(:billing_site => current_billing_site_id)
                  end
                else
                  flash[:error] = "Please import a CSV file!"
                  redirect_to import_invoice_invoices_path(:billing_site => current_billing_site_id)
                  return
                end
              else
                flash[:error] = "You cannot import two or more invoices with same start and end date!!. Check your invoice"
                redirect_to import_invoice_invoices_path(:billing_site => current_billing_site_id)
              end
            else
              flash[:error] = "Please upload a valid Invoice!!!!"
              redirect_to import_invoice_invoices_path(:billing_site => current_billing_site_id)
            end
          end
        else
          flash[:error] = "You have not selected any file!!!!"
          redirect_to import_invoice_invoices_path(:billing_site => current_billing_site_id)
        end
     else
      flash[:error] = "You have not import an invoice yet!"
      redirect_to import_invoice_invoices_path(:billing_site => current_billing_site_id)
    end
  end


  # get: /invoices/predictNew
  def predictNew
    @invoices = ImportedInvoice.all
  end


  # Select predictable billing period for Prediction method
  def select_date_period
    if !params[:invoice]["invoice_id"].blank?
      @imported_invoice = ImportedInvoice.find(params[:invoice][:invoice_id])
      @predictable_billing_periods = @imported_invoice.retail_plan.predictable_billing_periods
    else
      flash[:error] = "Please Select an Imported Invoice"
      redirect_to predictNew_invoices_path
    end
  end


  # Create a Predicted invoice in the system.
  #
  # Authors: Ethan, Chris,Charlene, Arun.,
  # post: /invoices/predict
  def create_predicted_invoice
    invoice_selected = params[:invoice]["invoice_selected"]
    @imported_invoice = ImportedInvoice.find(invoice_selected)
    @predictable_billing_periods = @imported_invoice.retail_plan.predictable_billing_periods
    @predictable_billing_periods.each do |predictable_billing_period|
      if predictable_billing_period.to_s == params[:invoice]["selected_date_period"].to_s
        @date_period_selected = predictable_billing_period
        break
      end
    end

    if !invoice_selected.blank? && !@date_period_selected.blank?
      #Based on the selection of imported invoice from the user
      attributes = Marshal.load( Marshal.dump(@imported_invoice.attributes))
      attributes["start_date"] = @date_period_selected[:start_date]
      attributes["end_date"] = @date_period_selected[:end_date]
      @invoice = PredictedInvoice.new(attributes.except!("file"))
      if @invoice.save
        respond_to do |format|
          format.html { render :show, notice: 'PredictedInvoice was successfully generated.' }
          format.json { render :show, status: :created, location: @invoice }
          return
        end
      else
        respond_to do |format|
          format.html { render :generateNew }
          format.json { render json: @invoice.errors, status: :unprocessable_entity }
          return
        end
      end
    else
      flash[:error] = "Some Fields Are Missing, Please Fill in All Required Items!"
      redirect_to predictNew_invoices_path
    end
  end

  # get: /invoices/generateNew
  def generateNew
    @invoices = ImportedInvoice.all
  end


  # Create a Generated invoice in the system from an imported invoice
  #
  # post: /invoices/generate
  def create_generated_invoice
    if !params[:invoice]["invoice_id"].blank?
      #Based on the selection of imported invoice from the user
      imported_invoice = ImportedInvoice.find(params[:invoice][:invoice_id])
      @invoice = GeneratedInvoice.new(imported_invoice.attributes.except!("file"))
      if @invoice.save
        respond_to do |format|
          format.html { render :show, notice: 'Invoice was successfully generated.' }
          format.json { render :show, status: :created, location: @invoice }
          return
        end
      else
        respond_to do |format|
          format.html { render :generateNew }
          format.json { render json: @invoice.errors, status: :unprocessable_entity }
          return
        end
      end
    else
      flash[:error] = "Some Fields Are Missing, Please Fill in All Required Items!"
      redirect_to generateNew_invoices_path
    end
  end


  # Compare Imported invoice with one associated generated invoice
  #
  # post: /invoices/compare
  def compare
    invoice = params[:invoice]
    imported = Invoice.find(invoice[:Imported_id])
    generated = Invoice.find(invoice[:Generated_id])
    @result = Invoice.compareInvoices(imported, generated)
    if @result
      respond_to do |format|
        # compare.html.erb
        format.html
      end
    end
  end
end
