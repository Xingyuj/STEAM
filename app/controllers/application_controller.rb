class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  # before_filter :authenticate
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


  def self.time hour, minute
    return Time.utc(2000, 'jan', 1, hour, minute)
  end

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == "admin" && password == "hydra"
    end
  end

  # Redirect user to 404 page if no route matches
  # Author:: Charlene
  def redirect_user
    redirect_to '/404'
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

end
