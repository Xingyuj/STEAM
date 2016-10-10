# config/initializers/scheduler.rb
require 'rufus-scheduler'

# Let's use the rufus-scheduler singleton
#
scheduler = Rufus::Scheduler.singleton

# The task for download file from ftp server every day
#
scheduler.every '1d' do
  puts "Download from ftp server"
  FtpServer.download
end