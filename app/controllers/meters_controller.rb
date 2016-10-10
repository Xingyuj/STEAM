class MetersController < ApplicationController
  # before_action :set_meter, only: [:show, :edit, :update, :destroy]
  before_action :set_meter, only: [:update, :destroy]


  # TODO Go over all Restful services


  # GET /meters
  # GET /meters.json
  # no index any more, charlene
  # def index
  #   @meters = Meter.all
  # end


  # GET /meters/1
  # GET /meters/1.json
  # no show any more, charlene
  # def show
  # end

  # GET /meters/new
  # no new any more, charlene
  # def new
  #   @meter = Meter.new
  # end

  # GET /meters/1/edit
  # no edit any more, charlene
  # def edit
  # end

  # POST /meters
  # POST /meters.json
  def create
    @meter = Meter.new(meter_params)
    @all_meters = current_user.meters
    count = 0
    @bsite = BillingSite.find_by(:id => @meter.billing_site_id)

    @all_meters.each do |value|
      if value.serial == @meter.serial
        count+=1
      end
    end

    respond_to do |format|
      if count == 0
        if @meter.nmi.length == 10
          if @meter.save
            format.html { redirect_to @bsite, notice: 'Meter was successfully created.' }
            # format.json { render :show, status: :created, location: @meter }
          else
            # format.html { render :new }
            # format.json { render json: @meter.errors, status: :unprocessable_entity }
            format.html { redirect_to @bsite, alert: 'Serial should be 2-12 characters. Please check the value and try again.' }
          end
        else
          format.html { redirect_to @bsite, alert: 'NMI should be 10 characters. Please check the value and try again.' }
        end
      else
        format.html { redirect_to @bsite, alert: 'A meter with same serial number exists already. Please check and try again' }
      end
    end
  end

  # PATCH/PUT /meters/1
  # PATCH/PUT /meters/1.json
  def update
    billingsite = @meter.billing_site_id

    respond_to do |format|
      if @meter.update(meter_params)
        # format.html { redirect_to @meter, notice: 'Meter was successfully updated.' }
        # format.json { render :show, status: :ok, location: @meter }

        format.html { redirect_to billing_site_path(billingsite), notice: 'Meter was successfully updated.' }
      else
        # format.html { render :edit }
        # format.json { render json: @meter.errors, status: :unprocessable_entity }

        format.html { redirect_to billing_site_path(billingsite), error: 'Meter was not successfully updated.' }
      end
    end
  end

  # DELETE /meters/1
  # DELETE /meters/1.json
  def destroy
    @meter.destroy
    respond_to do |format|
      format.html { redirect_to billing_site_url(@meter.billing_site_id), notice: 'Meter was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_meter
      @meter = Meter.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def meter_params
      params.require(:meter).permit(:serial, :nmi, :billing_site_id)
    end

    def set_user
      if params[:id]
        @user = User.find(params[:id])
      else
        @user = current_user
      end
    end

end

=begin
=======
      if @meter.nmi.length == 10
        if @meter.save
          # format.html { redirect_to @meter, notice: 'Meter was successfully created.' }
          # format.json { render :show, status: :created, location: @meter }

          billingsite = @meter.billing_site_id
          format.html { redirect_to billing_site_path(billingsite), notice: 'Meter was successfully created.' }
        else
          # format.html { render :new }
          # format.json { render json: @meter.errors, status: :unprocessable_entity }
        end
      else
        # format.html { redirect_to @meter, alert: 'NMI should be 10 characters. Please check the value and try again.' }
>>>>>>> 3419ebaaec7e13b9553b66b1e42e736da0cd3d76
=end