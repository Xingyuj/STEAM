json.array!(@meter_records) do |meter_record|
  json.extract! meter_record, :id
  json.url meter_record_url(meter_record, format: :json)
end
