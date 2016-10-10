module RetailPlansHelper

  #similar to RP.find(params[:id]) used in show and edit. Just created in case we need to make use of current session's retail plan.
  #not used as of now.
  def current_retail_plan
    @current_retail_plan = RetailPlan.find(params[:id])
  end

end
