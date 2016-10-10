json.array!(@ftp_servers) do |ftp_server|
  json.extract! ftp_server, :id, :name, :server, :username, :password, :last_poll, :next_poll, :poll_unit, :poll_value, :user_id
  json.url ftp_server_url(ftp_server, format: :json)
end
