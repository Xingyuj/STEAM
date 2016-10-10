class RetailPlansController < ApplicationController

  # Index page for Retail Plans
  # GET index
  def index
    @billing_site = BillingSite.find(params[:billing_site_id])
    @retail_plans = @billing_site.retail_plans.order(:id)
  end


  # GET new
  def new
    @billing_site = BillingSite.find(params[:billing_site_id])
    @retail_plan = RetailPlan.new
  end


  #GET show
  def show
    @retail_plan = set_retail_plan

  end

  #POST edit
  def edit
    @retail_plan = set_retail_plan

  end


  # Create a new retail plan.
  #
  # POST create
  def create
    @retail_plan = RetailPlan.new(retail_plan_params)   #method for defining parameters, based on Rails 4.x rule
    billing_site_id = @retail_plan.billing_site_id
    count=0

    #Validate that no two retail plans have same time frame
    @all_retail_plan = RetailPlan.where(:billing_site_id => billing_site_id)
    @all_retail_plan.each do |rp|
      if  (@retail_plan.start_date >= rp.start_date && @retail_plan.start_date <= rp.end_date)
        count+=1
      end
    end

    @all_retail_plan.each do |rp|
      if ( @retail_plan.end_date >= rp.start_date && @retail_plan.end_date <=rp.end_date)
        count+=1
      end
    end

    # Generic Validations
    if count==0 && @retail_plan.start_date < @retail_plan.end_date
      if (@retail_plan.discount > 0 && @retail_plan.discount < 1)
        if(@retail_plan.name != nil)
          logger.info "-------------------#{@all_retail_plan.length}"
          if @retail_plan.save
            redirect_to billing_site_url(billing_site_id), notice: 'retail plan was successfully created.'
            #redirect_to billing_site_retail_plan_url(@retail_plan), notice: "Retail Plan Created Successfully"
          else
            redirect_to new_billing_site_retail_plan_path, alert: "Unsuccessful Creation of Retail Plan"
          end
        else
          redirect_to new_billing_site_retail_plan_path, alert: "Name of the Retail Plan shall not be empty"
        end

      else
        redirect_to new_billing_site_retail_plan_path, alert: "Discount should be greater than 0 and less than 1"
      end

    else
      redirect_to new_billing_site_retail_plan_path, alert: "Start and End date of retail plan clashes. Unsuccessful Creation of Retail Plan. "
    end
  end


  # Update action applies when user edits the fields of existing retail plan.
  # Find the RP by id, apply update and redirect to the retail page's index atfer displaying success message
  #
  # POST update
  def update
    @retail_plan = set_retail_plan
    billing_site_id = @retail_plan.billing_site_id
    count = 0

    # debug
    # charge_factories_params = params[:retail_plan][:charge_factories_attributes]
    daily_usage_charges_params = params[:retail_plan][:daily_usage_charges_attributes]
    global_usage_charges_params = params[:retail_plan][:global_usage_charges_attributes]
    metering_charges_params = params[:retail_plan][:metering_charges_attributes]
    supply_charges_params = params[:retail_plan][:supply_charges_attributes]
    capacity_charges_params = params[:retail_plan][:capacity_charges_attributes]
    certificate_charges_params = params[:retail_plan][:certificate_charges_attributes]

    daily_usage_charges_params.values.each do |attrs|
      DailyUsageCharge.find(attrs[:id]).update_attributes(attrs.slice!(:id))
    end
    global_usage_charges_params.values.each do |attrs|
      GlobalUsageCharge.find(attrs[:id]).update_attributes(attrs.slice!(:id))
    end

    # MeteringCharge and SupplyCharge do not have attributes
    metering_charges_params.values.each do |attrs|
      MeteringCharge.find(attrs[:id]).update_attributes(attrs.slice!(:id))
    end
    supply_charges_params.values.each do |attrs|
      SupplyCharge.find(attrs[:id]).update_attributes(attrs.slice!(:id))
    end

    #Capacity and Certificate Charges atrributes
    capacity_charges_params.values.each do |attrs|
      CapacityCharge.find(attrs[:id]).update_attributes(attrs.slice!(:id))
    end
    certificate_charges_params.values.each do |attrs|
      CertificateCharge.find(attrs[:id]).update_attributes(attrs.slice!(:id))
    end

    plan_params = params[:retail_plan].slice!(:charge_factories_attributes, :daily_usage_charges_attributes, :global_usage_charges_attributes, :metering_charges_attributes, :supply_charges_attributes, :capacity_charges_attributes, :certificate_charges_attributes)
    permitted = plan_params.permit!

    if @retail_plan.update_attributes(permitted)
      redirect_to billing_site_retail_plan_url(@retail_plan), notice: "Update Success"
    else
      render :edit, alert: "Update Failed"
    end
  end


  # Destroy selected retail plan and return to corresponding billing site
  #
  # POST destroy
  def destroy
    @retail_plan = RetailPlan.find(params[:id])
    billing_site_id = @retail_plan.billing_site_id
    @retail_plan.destroy
    redirect_to billing_site_url(billing_site_id), notice: "Retail Plan successfully destroyed"
  end


  # Required parameters for Retail Plan forms.
  def set_retail_plan
    @retail_plan_set= RetailPlan.find(params[:id])
  end


  # Allow particular (or all) parameters of Retail plan to be saved
  def retail_plan_params
    params.require(:retail_plan).permit!
  end
end