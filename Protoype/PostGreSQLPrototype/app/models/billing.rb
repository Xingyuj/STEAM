class Billing < ActiveRecord::Base

  enum intervals: %i(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48)

  def self.num_time_periods
    return 48
  end

  def self.time_period_length
    return 1440 / num_time_periods
    return 1440 / :intervals.length
  end

  def self.time_periods
    return [
      { :start => 0, :end => 48 },
      { :start => 0, :end => 14 },
      { :start => 14, :end => 38 },
      { :start => 38, :end => 48 }
    ]
  end

end
