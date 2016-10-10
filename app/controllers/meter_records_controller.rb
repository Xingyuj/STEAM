class MeterRecordsController < ApplicationController

  before_action :set_meter_record, only: [:show, :edit, :update, :destroy]


  def get_meters
    meters = []

     meters.push Meter.find_by_serial('8056402')
     meters.push Meter.find_by_serial('2021')
    # meters.push Meter.find_by_serial('2022')
    # meters.push Meter.find_by_serial('2023')
    # meters.push Meter.find_by_serial('2024')
     meters.push Meter.find_by_serial('2025')
    return meters
  end


  def get_date_ranges

    return [
      {
        :start_date => '2010-01-02'.to_date,
        :end_date => '2011-01-01'.to_date,
      },
    ]


    return [
      {
        :start_date => '2001-07-01'.to_date,
        :end_date => '2002-07-06'.to_date,
      },
      # {
      #   :start_date => '2001-06-30'.to_date,
      #   :end_date => '2002-07-6'.to_date,
      # }
    ]
  end

  def get_dtps

    return [
        {
          :label => 'Retail Peak',
          :start_time => Time.utc(2001, 1, 1, 7, 0, 0),
          :end_time => Time.utc(2001, 1, 1, 20, 0, 0),
        },
        {
          :label => 'Network Peak',
          :start_time => Time.utc(2001, 1, 1, 7, 0, 0),
          :end_time => Time.utc(2001, 1, 1, 20, 0, 0),
        },
        {
          :label => 'Retail Off-Peak',
          :start_time => Time.utc(2001, 1, 1, 22, 0, 0),
          :end_time => Time.utc(2001, 1, 1, 7, 0, 0),
        },
        {
          :label => 'Network Off-Peak',
          :start_time => Time.utc(2001, 1, 1, 22, 0, 0),
          :end_time => Time.utc(2001, 1, 1, 7, 0, 0),
        }
      ]



    return [
      {
        :label => "Peak",
        :start_time => Time.new(2000, 1, 1, 7, 0),
        :end_time => Time.new(2000, 1, 1, 19, 0),
      },
      {
        :label => "Shoulder",
        :start_time => Time.new(2000, 1, 1, 19, 0),
        :end_time => Time.new(2000, 1, 1, 22, 0),
      },
      {
        :label => "Off-Peak",
        :start_time => Time.new(2000, 1, 1, 22, 0),
        :end_time => Time.new(2000, 1, 1, 7, 0),
      },
    ]
  end

# Calls the static class method Meter.import
  def import_nem12

    truncate_records
    truncate_aggregations

    meters = get_meters
    #directory = "homes/reuben/test"
    #directory = "homes/reuben/09-07-2015"
    #directory = "homes/reuben/1"
    #directory = "homes/testdata"
    directory = "homes/reuben/clariti"
    result = Meter.import_nem12(directory, meters)
    logger.info result
    redirect_to action: 'index'
  end

# Calls the Meter.usage static class method
  def multiple_usage
    date_ranges = get_date_ranges
    meters = get_meters
    dtps = get_dtps

    #MeterAggregation.aggregate_missing_data date_ranges, dtps, meters

    #dtps = []

    #usages = Meter.usage_by_meter date_ranges, dtps, meters
    #usages = Meter.detailed_usage_by_meter date_ranges, dtps, meters
    #usages = Meter.usage_by_time date_ranges, dtps, meters
    usages = {}

    t = Benchmark.measure {
      usages = Meter.detailed_usage_by_time date_ranges, dtps, meters
    }
    logger.info "Time taken => #{t}"
    # usages[:query_time] = t
    render :json => usages

    #redirect_to action: 'index'
  end

  def multiple_predicted_usage
    date_ranges = get_date_ranges
    meters = get_meters
    dtps = Meter.get_daily_time_periods meters

    #usages = Meter.predicted_usage_by_meter date_ranges, dtps, meters
    #usages = Meter.predicted_usage_by_time date_ranges, dtps, meters
    usages = Meter.detailed_predicted_usage_by_meter date_ranges, dtps, meters
    #usages = Meter.detailed_predicted_usage_by_time date_ranges, dtps, meters
    render :json => usages

    #redirect_to action: 'index'
  end


# Calls the meter.usage instance method
  def single_usage
    meter = get_meters[3]
    date_ranges = get_date_ranges
    dtps = Meter.get_daily_time_periods [meter]

#    usage = meter.usage_by_meter(date_ranges, dtps)
#    usage = meter.usage_by_time(date_ranges, dtps)
    usage = meter.detailed_usage_by_meter(date_ranges, dtps)
#    usage = meter.detailed_usage_by_time(date_ranges, dtps)

    render :json => usage

#    redirect_to action: 'index'
  end

# Calls the meter.usage instance method
  def single_predicted_usage
    meter = get_meters[3]
    date_ranges = get_date_ranges
    dtps = Meter.get_daily_time_periods [meter]

#    usage = meter.predicted_usage_by_meter(date_ranges, dtps)
#    usage = meter.predicted_usage_by_time(date_ranges, dtps)
#    usage = meter.detailed_predicted_usage_by_meter(date_ranges, dtps)
    usage = meter.detailed_predicted_usage_by_time(date_ranges, dtps)

    render :json => usage

#    redirect_to action: 'index'
  end












# Empty the Records table, restart the index
  def truncate
    truncate_records
    redirect_to action: 'index'
  end

  def truncate_records
    sql = "TRUNCATE TABLE meter_records RESTART IDENTITY;"
    result = ActiveRecord::Base.connection.raw_connection.exec sql
  end

  def truncate_aggregations
    sql = "TRUNCATE TABLE meter_aggregations RESTART IDENTITY;"
    result = ActiveRecord::Base.connection.raw_connection.exec sql
  end

  # GET /meter_records
  # GET /meter_records.json
  def index
    @meter_records = MeterRecord.all
  end

  # GET /meter_records/1
  # GET /meter_records/1.json
  def show
  end

  # GET /meter_records/new
  def new
    @meter_record = MeterRecord.new
  end

  # GET /meter_records/1/edit
  def edit
  end

  # POST /meter_records
  # POST /meter_records.json
  def create
    @meter_record = MeterRecord.new(meter_record_params)

    respond_to do |format|
      if @meter_record.save
        format.html { redirect_to @meter_record, notice: 'Meter record was successfully created.' }
        format.json { render :show, status: :created, location: @meter_record }
      else
        format.html { render :new }
        format.json { render json: @meter_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /meter_records/1
  # PATCH/PUT /meter_records/1.json
  def update
    respond_to do |format|
      if @meter_record.update(meter_record_params)
        format.html { redirect_to @meter_record, notice: 'Meter record was successfully updated.' }
        format.json { render :show, status: :ok, location: @meter_record }
      else
        format.html { render :edit }
        format.json { render json: @meter_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /meter_records/1
  # DELETE /meter_records/1.json
  def destroy
    @meter_record.destroy
    respond_to do |format|
      format.html { redirect_to meter_records_url, notice: 'Meter record was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_meter_record
      @meter_record = MeterRecord.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def meter_record_params
      params.require(:meter_record).permit(:index)
    end
end
