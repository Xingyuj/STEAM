json.array!(@meter_aggregations) do |meter_aggregation|
  json.extract! meter_aggregation, :id
  json.url meter_aggregation_url(meter_aggregation, format: :json)
end
