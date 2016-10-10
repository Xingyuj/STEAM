class BillingSitesController < ApplicationController
  before_action :set_billing_site, only: [:show, :edit, :update, :destroy, :show_predict_usage, :show_usage]

  # GET /billing_sites
  # GET /billing_sites.json
  def index
    @billing_sites = BillingSite.all.order(:id)

  end


  # GET /billing_sites/1/predictions
  def show_predict_usage
    # get the predicted electricity invoice
    start_date = Date.today
    end_date = Date.new(start_date.next_year.year,6,30) if start_date.month < 7
    end_date = Date.new(start_date.next_year.next_year.year, 6, 30) if start_date.month >= 7
    # get the meters belongs to the billing_site
    meters = @billing_site.meters
    # get the daily time periods from the retail plan
    daily_time_periods = RetailPlan.dailyTimePeriods meters
    puts daily_time_periods
    # create date_range input
    date_ranges = generate_date_ranges(start_date, end_date, 'Daily')
    dr = [{:start_date => start_date, :end_date => end_date}]
    usages = Meter.detailed_predicted_usage_by_time(dr, daily_time_periods, meters.to_a)
    # puts Benchmark.measure {format_converter usages, 'line', 'Daily'}
    predict_format_converter usages[0]
    # get the predicted invoices
    @predict_invoices = Invoice.get_prediction_invoice @billing_site.id
  end


  # GET /billing_sites/1/usage
  def show_usage
    query = params
    # Default data
    @start_date = Date.today.last_month
    @end_date = Date.today
    @interval = 'Daily'
    @type = 'line'
    #update the query
    if not query[:start_date].nil?
      @start_date = Date.parse(query[:start_date])
      @end_date = Date.parse(query[:end_date])
      @interval = query[:interval]
      @type = query[:type]
    end
    # get the meters belongs to the billing_site
    meters = @billing_site.meters

    # get the daily time periods from the retail plan
    daily_time_periods = RetailPlan.dailyTimePeriods meters
    puts daily_time_periods

    # create date_range input
    date_ranges = generate_date_ranges(@start_date, @end_date, @interval)
    # get the usage data
    usages = Meter.usage_by_time(date_ranges, daily_time_periods, meters.to_a)

    # convert the data format which can be used in javascript
    # format_converter usages[0], @type
    puts usages
    format_converter usages, daily_time_periods, @interval
  end


  # GET /billing_sites/1
  # GET /billing_sites/1.json
  def show
    # default dates
    start_date = Date.today - 1.year
    end_date = Date.today
    if (to = isDate params[:dateTo])
      if (from = isDate params[:dateFrom])
        #only change if both are good dates
        if from < to
          start_date = from
          end_date = to
        end
      end
    end
    @start_date = start_date
    @end_date = end_date
    @billing_site = set_billing_site
    @meters = @billing_site.meters.order(:id)
    @retail_plans = @billing_site.retail_plans.order(:id)
    @invoices = []

    # select from the associated Imported invoices those between start and end date
    importedInvoices = @billing_site.invoices(true).where(actable_type: ImportedInvoice,
                                                     start_date: start_date..end_date)

    #if there are imported invoices in system find their generated ones
    if !importedInvoices.blank?
      importedInvoices.each do |importedInvoice|
        generatedInvoices = @billing_site.invoices(true).where(actable_type: GeneratedInvoice,
                                                          start_date: importedInvoice.start_date,
                                                          end_date: importedInvoice.end_date)
        invoiceHash = {}

        invoiceHash[:Imported] = importedInvoice
        # process generated invoices, add values to hash
        generatedValues = []
        if !generatedInvoices.blank?
          generatedInvoices.each do |generatedInvoice|
            hash = {}
            hash[:id] = generatedInvoice.id

            # float needed for frontend
            hash[:total] = generatedInvoice.total.to_f
            generatedValues.push([generatedInvoice.created_at, hash])
          end
          invoiceHash[:GeneratedValues] = generatedValues
        else
          invoiceHash[:GeneratedValues] = []
        end
        @invoices.push(invoiceHash)
      end
    else
      @invoices =[]
    end
  end

  # GET /billing_sites/new
  def new
    @billing_site = BillingSite.new
  end


  # GET /billing_sites/1/edit
  def edit
  end


  # POST /billing_sites
  # POST /billing_sites.json
  def create
    @billing_site = BillingSite.new(billing_site_params)
    @bs = @billing_site.site_id
    @site = Site.find_by(:id => @bs)
    @all_billing_site = BillingSite.where(:site_id => @bs)
    count = 0

    #No two Billing site in same site shall have similar names
    @all_billing_site.each do |value|
      if value.name  == @billing_site.name
        count+=1
      end
    end
    respond_to do |format|
      if !@billing_site.name.blank?
        if count == 0
          if @billing_site.save
            format.html { redirect_to @billing_site, notice: 'Billing site was successfully created.' }
            format.json { render :show, status: :created, location: @billing_site }
          else
            format.html { render :new }
            format.json { render json: @billing_site.errors, status: :unprocessable_entity }
          end
        else
          format.html { redirect_to @site , alert: "Another Billing Site exists with the same name. Please give a new name" }
          format.json { render json: @billing_site.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to @site , alert: "Billing Site name cannot by empty. Try again" }
        format.json { render json: @billing_site.errors, status: :unprocessable_entity }
      end
    end
  end


  # PATCH/PUT /billing_sites/1
  # PATCH/PUT /billing_sites/1.json
  def update
    respond_to do |format|
      if @billing_site.update(billing_site_params)
        format.html { redirect_to @billing_site, notice: 'Billing site was successfully updated.' }
        format.json { render :show, status: :ok, location: @billing_site }
      else
        format.html { render :edit }
        format.json { render json: @billing_site.errors, status: :unprocessable_entity }
      end
    end
  end


  # DELETE /billing_sites/1
  # DELETE /billing_sites/1.json
  def destroy
    site = @billing_site.site_id
    @billing_site.destroy
    respond_to do |format|
      # format.html { redirect_to billing_sites_url, notice: 'Billing site was successfully destroyed.' }
      format.html { redirect_to site_path(site), notice: 'Billing site was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


  ##
  # Convert the usage into the format what the google chart can be used
  #
  # ==== Attributes
  #
  # * +usages+ - The detail electricity usages of specific date period
  # * +daily_time_periods+ - the date range with start date and end date
  # * +interval+ - The interval of the date e.g 'Daily', 'Monthly', 'Quarterly'
  #
  # ==== Examples
  #
  # format_converter {:start_time, :end_time, ...}, 'line', 'Daily'
  #
  def format_converter (usages, daily_time_periods, interval)
    @date = [] # Date List
    @total = [] # Total usage List
    @lines = [] # Label list
    @labels = [] # Lines list, each element is the list of one line usage
    @table_array = [] # table structure
    @table_array.append("date[i]")  #["date[i]", "total[i]", "line[0][i]", "line[1][i]"]
    @table_array.append('total[i]')
    daily_time_periods.each_with_index do |dtp, index|
      @name ="lines[#{index.to_s}][i]"
      @table_array.append(@name)
      @lines.append([]) #[[], []]
      @labels.append(dtp[:label])
    end
    usages.each_with_index do |usage, usage_index|

      @date.append(usage[:start_date].to_s) if interval == 'Daily' #[2012-1-1, 2012-2-2]
      @date.append(usage[:start_date].strftime('%B')) if interval == 'Monthly'
      @date.append("#{usage[:start_date].beginning_of_quarter.strftime("%B")}
        --#{usage[:start_date].end_of_quarter.strftime('%B')}") if interval == 'Quarterly'
      @total.append(usage[:usage]) #[total1, total2]

      usage[:daily_time_periods].each_with_index do |period, index|
        @lines[index].append(period[:usage]) #[[peak-usage], [off-peak-usage]]
      end if usage[:daily_time_periods]
      # if daily_time_periods is empty, add nil for each lines data
      daily_time_periods.each_with_index do |period, index|
        @lines[index].append(nil)
      end if usage[:daily_time_periods] == []
    end
  end


  def get_prediction_invoice billing_site_id
    @predicted_invoices = []
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
            @predicted_invoices << @predicted_invoice
      else
            logger.debug "predicted_invoices for '"+@imported_invoice.specific.file+"' fail to create"
      end
    end
  end
  ##
  # Convert the usage into the format what the google chart can be used
  #
  # ==== Attributes
  #
  # * +usages+ - The usage json message
  #
  #

  def predict_format_converter usages
    @date = []
    @total = []
    @lines = []
    @labels = []
    @table_array = []
    usages[:daily_usage].each do |usage|
      @date.append(usage[:date].to_s)

      @total.append(usage[:usage])
    end
    @table_array.append("date[i]")
    @table_array.append("total[i]")
    usages[:daily_time_periods].each_with_index do |period, index|
      @name ="lines[#{index.to_s}][i]"
      @table_array.append(@name)
      @lines.append([])
      @labels.append(period[:label])
      period[:daily_usage].each do |usage|
        @lines[index].append(usage[:usage])

      end
    end
  end

  ##
  # generate the date ranges based on the interval and return a array of date range
  #
  # ==== Attributes
  #
  # * +start_date+ - The start date of period
  # * +end_Date+ - The end date of period
  # * +interval+ - The interval of each date range
  #
  # ==== Examples
  #
  # generate_date_ranges {:start_time, :end_time}, {:start_Time => ..., :end_time => ...}, 'Daily'
  #
  def generate_date_ranges(start_date, end_date, interval)
    date_ranges = []
    s_date = start_date
    case interval
      when 'Daily'
        while s_date < end_date
          e_date = s_date
          date_ranges.append({:start_date => s_date, :end_date => e_date})
          s_date = s_date.tomorrow
        end
      when 'Monthly'
        while s_date.end_of_month < end_date
          e_date = s_date.end_of_month
          date_ranges.append({:start_date => s_date, :end_date => e_date})
          s_date = s_date.end_of_month.tomorrow
        end
      when 'Quarterly'
        while s_date.end_of_quarter < end_date
          e_date = s_date.end_of_quarter
          date_ranges.append({:start_date => s_date, :end_date => e_date})
          s_date = s_date.end_of_quarter.tomorrow
        end
        end
    date_ranges.append({:start_date => s_date, :end_date => end_date})
  end

    # Never trust parameters from the scary internet, only allow the white list through.
    def billing_site_params
      params.require(:billing_site).permit(:name, :site_id, :created)
    end

    #check if object is a Date from the return of the form (string form)
    def isDate stringDate
      if stringDate.blank?
        return false
      elsif stringDate.is_a?(String)
        if date = stringDate.to_date
          return date
        end
      end
      return false
    end


  private

  # Use callbacks to share common setup or constraints between actions.
  def set_billing_site
    @billing_site = BillingSite.find(params[:id])
  end

  # Define the parameters that needs to be saved for Billing sites
  def billing_site_params
    params.require(:billing_site).permit(:name, :site_id, :created)
  end

end
