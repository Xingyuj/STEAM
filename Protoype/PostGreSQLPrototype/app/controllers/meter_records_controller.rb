class MeterRecordsController < ApplicationController
  before_action :set_meter_record, only: [:show, :edit, :update, :destroy]

  # GET /meter_records
  # GET /meter_records.json
  def index
    @meter_records = MeterRecord.all.order(:date, :meter_serial)
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
      params[:meter_record]
#      params.require(:meter_record).permit(:values)

    end
end
