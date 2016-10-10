json.array!(@meter_aggregates) do |meter_aggregate|
  json.extract! meter_aggregate, :id
  json.url meter_aggregate_url(meter_aggregate, format: :json)
end
