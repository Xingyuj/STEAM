class MeterAggregation < ActiveRecord::Base
    self.primary_keys = :meter_serial, :date, :start_time, :end_time

end
