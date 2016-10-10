class MeterPredictor < ActiveRecord::Base
  actable
  belongs_to :meter, dependent: :destroy

  # These functions should be implemented in subclasses,
  # raises an error if not implemented in them but are called
  def self.calculate(start_date, end_date, daily_time_period, meter)
    raise NotImplementedError, "Method 'usage_by_meter' not implemented in subclass"
  end


  def self.usage_by_meter(start_date, end_date, daily_time_period, meter)
    raise NotImplementedError, "Method 'usage_by_meter' not implemented in subclass"
  end

  def self.usage_by_time(start_date, end_date, daily_time_period, meter)
    raise NotImplementedError, "Method 'usage_by_time' not implemented in subclass"
  end

  def self.detailed_usage_by_meter(date_range, daily_time_period, meter)
    raise NotImplementedError, "Method 'calculate' not implemented in subclass"
  end

  def self.detailed_usage_by_time(date_range, daily_time_period, meter)
    raise NotImplementedError, "Method 'detailed_usage_by_meter' not implemented in subclass"
  end

  def usage_by_meter(start_date, end_date, daily_time_period)
    raise NotImplementedError, "Instance Method 'usage_by_meter' not implemented in subclass"
  end

  def usage_by_time(start_date, end_date, daily_time_period)
    raise NotImplementedError, "Instance Method 'usage_by_time' not implemented in subclass"
  end

end
