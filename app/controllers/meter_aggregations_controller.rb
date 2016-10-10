class MeterAggregationsController < ApplicationController
  before_action :set_meter_aggregation, only: [:show, :edit, :update, :destroy]


# Empty the Aggregations table, restart the index
  def truncate
    sql = "TRUNCATE TABLE meter_aggregations RESTART IDENTITY;"
    result = ActiveRecord::Base.connection.raw_connection.exec sql
    redirect_to action: 'index'
  end

  # GET /meter_aggregations
  # GET /meter_aggregations.json
  def index
    @meter_aggregations = MeterAggregation.all.order(:date, :meter_id, :start_time, :end_time)
  end

  # GET /meter_aggregations/1
  # GET /meter_aggregations/1.json
  def show
  end

  # GET /meter_aggregations/new
  def new
    @meter_aggregation = MeterAggregation.new
  end

  # GET /meter_aggregations/1/edit
  def edit
  end

  # POST /meter_aggregations
  # POST /meter_aggregations.json
  def create
    @meter_aggregation = MeterAggregation.new(meter_aggregation_params)

    respond_to do |format|
      if @meter_aggregation.save
        format.html { redirect_to @meter_aggregation, notice: 'Meter aggregation was successfully created.' }
        format.json { render :show, status: :created, location: @meter_aggregation }
      else
        format.html { render :new }
        format.json { render json: @meter_aggregation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /meter_aggregations/1
  # PATCH/PUT /meter_aggregations/1.json
  def update
    respond_to do |format|
      if @meter_aggregation.update(meter_aggregation_params)
        format.html { redirect_to @meter_aggregation, notice: 'Meter aggregation was successfully updated.' }
        format.json { render :show, status: :ok, location: @meter_aggregation }
      else
        format.html { render :edit }
        format.json { render json: @meter_aggregation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /meter_aggregations/1
  # DELETE /meter_aggregations/1.json
  def destroy
    @meter_aggregation.destroy
    respond_to do |format|
      format.html { redirect_to meter_aggregations_url, notice: 'Meter aggregation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_meter_aggregation
      @meter_aggregation = MeterAggregation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def meter_aggregation_params
      params[:meter_aggregation]
    end
end
