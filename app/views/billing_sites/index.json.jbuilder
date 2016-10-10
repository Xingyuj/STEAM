json.array!(@billing_sites) do |billing_site|
  json.extract! billing_site, :id, :name, :site_id, :created
  json.url billing_site_url(billing_site, format: :json)
end
