json.array!(@billings) do |billing|
  json.extract! billing, :id
  json.url billing_url(billing, format: :json)
end
