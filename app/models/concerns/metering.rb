module Metering
  extend ActiveSupport::Concern

  module ClassMethods

# Transforms a PostGresql result object into a hash, used in development
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +result+ a pgsql result
#
# === Outputs
# Returns a string
    def pgresult_to_hash result
      response = result.map do |r|
        row = {}
        r.each do |k, v|
          row[k.to_sym] = v
        end
      end
      return response
    end



# Gets an all day daily time periodtime
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# None
#
# === Outputs
# A hash, containing +:start_time+ and +:end_time+
    def all_day
      return {
        :start_time => midday,
        :end_time => midday
      }
    end


# Gets the time at midday
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# None
#
# === Outputs
# Returns a Time object, at midday
   def midday
     Time.new(2000, 1, 1, 12, 0)
   end

#   Returns the number of minutes in a day
    def minutes_in_day
      return 1440
    end

#   Returns the number of minutes in an hour
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# None
#
# === Outputs
# Integer 60
    def minutes_in_hour
      return 60
    end

#   Converts a Time object to an integer, which is the minute of the day
    def time_to_minute t
      return t.hour.to_i * minutes_in_hour + t.min.to_i
    end


################################################################################
# Errors

    def directoryNotFoundError d
      return {
        :errors => [ "Directory #{d} was not found." ]
      }
    end

    def badMeterError
      return {
        :errors => [ "That doesn't look like a meter to me." ]
      }
    end

    def badDateError
      return {
        :errors => [ "That doesn't look like a Date to me." ]
      }
    end

    def badTimeError
      return {
        :errors => [ "That doesn't look like a Time to me." ]
      }
    end

    def bad_date_range_error dr
      return {
        :errors => [ "Invalid date range. #{dr}" ]
      }
    end

    def bad_daily_time_periods_error dtp
      return {
        :errors => [ "Invalid daily time period. #{dtp}" ]
      }
    end


# Returns an array of valid units of measurement for NEM12
  def nem12_uom
    return [

#     Unit of power
      'wh',
      'kwh',
      'mwh',

      'varh',
      'kvarh',
      'mvarh',

      'vah',
      'kvah',
      'mvah',

#     Unit of something else
      'w',
      'kw',
      'mw',

      'var',
      'mvar',
      'kvar',

      'va',
      'kva',
      'mva',

      'v',
      'kv',

      'a',
      'ka',

      'pf'
    ]
  end

# Returns the unit by which to multiply an aggregation
# to get kwh
# TODO Look over this with someone that dabbles in physics
  def nem12_uom_to_kwh_multiplier old_uom

    uom = {
      'w' =>  1,
      'kw' => 1,
      'mw' => 1,

      'wh' => 1.0 / 1000,
      'kwh' => 1,
      'mwh' => 1000,

      'varh' => 1.0 / 1000,
      'kvarh' => 1,
      'mvarh' => 1000,

      'var' => 1.0 / 1000,
      'kvar' => 1,
      'mvar' => 1000,

      'vah' => 1.0 / 1000,
      'kvah' => 1,
      'mvah' => 1000,

      'va' => 1.0 / 1000,
      'kva' => 1,
      'mva' => 1000,

      'v' => 1.0 / 1000,
      'kv' => 1,

      'a' => 1.0 / 1000,
      'ka' => 1,

      'pf' => 1
    }
    return uom[old_uom.downcase]
  end


# Returns the Unit of Measurement in terms of k
# i.e., 'wh' return 'kwh' etc.
  def nem12_uom_to_kuom old_uom

    uom = {
      'w' =>  'kw',
      'kw' => 'kw',
      'mw' => 'kw',

      'wh' => 'kwh',
      'kwh' => 'kwh',
      'mwh' => 'kwh',

      'varh' => 'kvarh',
      'kvarh' => 'kvarh',
      'mvarh' => 'kvarh',

      'var' => 'kvar',
      'kvar' => 'kvar',
      'mvar' => 'kvar',

      'vah' => 'kvah',
      'kvah' => 'kvah',
      'mvah' => 'kvah',

      'va' => 'kva',
      'kva' => 'kva',
      'mva' => 'kva',

      'v' => 'kv',
      'kv' => 'kv',

      'a' => 'ka',
      'ka' => 'ka',

      'pf' => 'pf'
    }
    return uom[old_uom.downcase]
  end







################################################################################
# Validating arguments passed to public methods

    def is_array_of_meters meters
      return false unless meters.kind_of?(Array)
      meters.each do |m|
        return false unless is_meter m
      end
      return true
    end

#   Return true if m is a Meter
    def is_meter m
      return false unless m.instance_of? Meter
      return true
    end

#   Returns true if d is a Date
    def is_date d
      return false unless d.instance_of? Date
      return true
    end

#   Returns true if t is a Time
    def is_time t
      return false unless t.instance_of? Time
      return true
    end

    def is_valid_date_ranges drs
      begin
        drs.each do |dr|
          return false unless dr[:start_date].instance_of? Date \
            and dr[:end_date].instance_of? Date \
            and dr[:start_date] <= dr[:end_date]
        end
      rescue
        return false
      end
      return true
    end

    def is_valid_daily_time_periods dtps
      begin
        dtps.each do |dtp|
          return false unless dtp[:start_time].instance_of? Time \
            and dtp[:end_time].instance_of? Time
        end
      rescue
        return false
      end
      return true
    end



# Dumps the contents of a query result to the logger
  def log_pg_result result
    logger.info "Logging Postgresql Result"
    logger.info "Result: #{result}"
    result.each do |row|
      logger.info "Row: #{row}"
    end
    logger.info "\n"
  end



  end

end