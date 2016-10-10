require 'rubygems'
require 'active_support'

class UsersController < ApplicationController
  before_action :set_user, only: [:show]
  # GET /users/1
  def show
  end

  # GET /users/import
  # Upload NEM12
  def upload_nem12

  end

  # POST /users/import
  # Store the nem12 file into user's home directory
  def import_nem12

    current_time = Time.now.to_i.to_s # get the unix time
    num = 0
    if params[:files]
      params[:files].each do |file|
        case File.extname(file.original_filename)
          when '.csv'
            num += 1
            tmp_file = file.tempfile
            destiny_file = File.join('homes', current_user.name,current_time, file.original_filename)
            # Create directory
            FileUtils.mkdir_p "homes/#{current_user.name}/#{current_time}"
            # Copy the upload file into sepecific directory
            FileUtils.move tmp_file.path, destiny_file

            # call import_nem12 function in meter model to store the data in file
            Meter.import_nem12(File.dirname(destiny_file), current_user.meters.to_a)
        end
      end
    # return to user profile page when finished
      redirect_to users_import_path, notice: "#{num} files uploaded!"
    else
      flash[:error] = "You have not selected any file!!!!"
      redirect_to users_import_path
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    if params[:id]
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end

end
