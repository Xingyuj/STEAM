json.array!(@sites) do |site|
  json.extract! site, :id, :name, :address1, :address2, :user_id, :created
  json.url site_url(site, format: :json)
end
