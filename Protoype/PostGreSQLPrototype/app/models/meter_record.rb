class MeterRecord < ActiveRecord::Base
  self.primary_keys = :meter_serial, :date

end
