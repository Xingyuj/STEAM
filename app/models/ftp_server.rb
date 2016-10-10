class FtpServer < ActiveRecord::Base
  belongs_to :user
  enum poll_unit: [ :days, :weeks, :months ]  # Set the Enum type for the poll_unit

  validate :name_presence

  def name_presence
    if name.blank?
      errors.add(:name,"Cannot be blank")
    end

    if server.blank?
      errors.add(:server,"Cannot be blank")
    end
  end

  ##
  # Update the last poll date and next poll date
  #
  # ==== Attributes
  #
  # * +server+ - The server instance
  #
  def self.update_poll_dates server
    server.last_poll = Date.today
    case server.poll_unit
      when "days"
        server.next_poll += server.poll_value.days
      when "weeks"
        server.next_poll += server.poll_value.weeks
      when "months"
        server.next_poll += server.poll_value.months
    end
    server.save
  end

  # Download the data from all the FTP server
  #
  def self.download
    # import the ftp support
    puts "Start running"
    require 'net/ftp'
    servers = FtpServer.where("next_poll <= ?", Date.today)
    if !servers.nil?
      servers.each do |server|
        # deal with the servers which next poll date is today
        if server.next_poll == Date.today
          # get the information of the server
          host = server.server
          username = server.username
          password = server.password
          user = server.user.name
          current_time = Time.now.to_i.to_s
          ftp = Net::FTP.new
          # connect the server
          ftp.connect(host,21)
          # login with username and password
          ftp.login(username,password)
          ftp.passive = true
          # open the directory
          ftp.chdir("FTP/")
          # Returns an array of filenames in the remote directory.
          filenames = ftp.nlst("*.csv")
          puts filenames
          FileUtils.mkdir_p "homes/#{user}/#{host}/#{current_time}"
          puts "Create directory successful"
          #Loop by value
          filenames.each do |remote_file| #Loop through each element of the array
            if ftp.mtime(remote_file) > server.last_poll
              local_file = File.join("homes/#{user}/#{host}/#{current_time}", remote_file)
              # copy the file from remote to local
              ftp.getbinaryfile(remote_file,local_file) #Get the file
              # call import_nem12 function in meter model to store the data in file
              Meter.import_nem12(File.dirname(local_file), server.user.meters.to_a)
            end
          end
          puts "File download successful"
          ftp.close
          # update the poll date
          update_poll_dates server
        end
      end
    end
  end
end
