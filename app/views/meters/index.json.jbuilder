json.array!(@meters) do |meter|
  json.extract! meter, :id, :serial, :nmi, :billing_site_id
  json.url meter_url(meter, format: :json)
end
