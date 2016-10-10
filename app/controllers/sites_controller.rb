class SitesController < ApplicationController
  before_action :set_site, only: [:show, :edit, :update, :destroy]

  # GET /sites
  # GET /sites.json
  def index
    # order by ID
    @sites = current_user.sites.order(:id)
  end

  # GET /sites/1
  # GET /sites/1.json
  def show
    @billing_sites = @site.billing_sites.order(:id)
  end

  # GET /sites/new
  def new
    @site = Site.new
  end

  # GET /sites/1/edit
  def edit
  end

  # POST /sites
  # POST /sites.json
  def create
    @site = Site.new(site_params)
    @all_sites = current_user.sites
    count = 0

    #two sites for the same user shall not have similar names
    @all_sites.each do |value|
      if value.name == @site.name
        count+=1
      end
    end

    respond_to do |format|
      if !@site.name.blank?
        if count==0
          if @site.save
            format.html { redirect_to @site, notice: 'Site was successfully created.' }
            format.json { render :show, status: :created, location: @site }
          else
            format.html { render :new }
            format.json { render json: @site.errors, status: :unprocessable_entity }
          end
        else
          format.html { redirect_to @site, alert: "Site already exists. Try again" }
          format.json { render json: @site.errors, status: :unprocessable_entity }
        end
      else
        format.html { redirect_to @site, alert: "Site name Cannot be empty. Try again" }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
    respond_to do |format|
      if @site.update(site_params)
        format.html { redirect_to @site, notice: 'Site was successfully updated.' }
        format.json { render :show, status: :ok, location: @site }
      else
        format.html { render :edit }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sites/1
  # DELETE /sites/1.json
  def destroy
    @site.destroy
    respond_to do |format|
      format.html { redirect_to sites_url, notice: 'Site was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_site
      @site = Site.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def site_params
      params.require(:site).permit(:name, :address1, :address2, :user_id, :created)
    end

    def set_user
      if params[:id]
        @user = User.find(params[:id])
      else
        @user = current_user
      end
    end
end
