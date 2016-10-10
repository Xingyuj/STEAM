class LinearRegressionPredictor < ActiveRecord::Base
  acts_as :meter_predictor

  # need a reference date for creating integers for regression gem with the appropriate offsets
  REFERENCE_DATE = Date::strptime('01-01-2015','%d-%m-%Y')

  #=============================================================================================
  # External methods (specified in design document)

  # Calculates and saves a predictor of type LinearRegressionPredictor for
  # each daily time period and meter in the arrays
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +start_date+ - Unused
  # * +end_date+ - Unused
  # * +daily_time_period+ - array of daily time periods, hash is specified in
  # meter interface of design document
  # * +meter+ - array of meters
  #
  # === Preconditions
  # Expects variables to be the correct type (see above)
  # daily time periods have an end time after the start (or equal)
  # The Metering system has usage for this meter
  #
  # === Outputs
  # adds LinearRegressionPredictor to database
  # (includes meterPredictor table entry via the inheritance)
  # no return value
  def self.calculate(start_date, end_date, daily_time_period, meter)
    #start_date and end_date parameters are currently unused by this method
    check_times(daily_time_period)
    check_meters(meter)
    #get meter data broken down by day for daily time periods and meters
    from = Date::strptime('01-01-1900','%d-%m-%Y') # earliest date, used to get all usage
    to = Date.current #get usage up to now
    date_range = [{:start_date => from, :end_date => to}]
    detailed_usage = (Meter.detailed_usage_by_meter(date_range, daily_time_period, meter))

    #   We can loop the usage results rather than hard code a zero index
    detailed_usage.each do |usage|

      # get the array of usage per meter
      meter_usages = usage[:meters]

#     If there is no usage, don't do this bit
      if not meter_usages.blank?
        #loop through the meters and usages
        meter.zip(meter_usages).each do |each_meter, meter_usage|
          if not meter_usage.blank?
            # get the array of usage per daily time period
            daily_time_period_usages = meter_usage[:daily_time_periods]
            if not daily_time_period_usages.blank?
              #loop through the daily time period usages
              daily_time_period_usages.each do |daily_time_period_usage|
                #initialise arrays to zero
                dates = []
                usages = []
                # get the array of daily usage
                daily_usages = daily_time_period_usage[:daily_usage]
                #loop through the daily time period usages
                daily_usages.each do |daily_usage|
                  dates.push(daily_usage[:date])
                  usages.push(daily_usage[:usage])
                end
                # calculate the values used for the prediction
                intercept, slope = make_prediction(usages, dates)
                LinearRegressionPredictor.create(meter_id: each_meter.id,
                                                 start_time: daily_time_period_usage[:start_time],
                                                 end_time: daily_time_period_usage[:end_time],
                                                 calculated_date: to,
                                                 a: intercept,
                                                 b: slope)
              end
            end
          end
        end
      end
    end
  end

  # Calculates usage, uses #use for the functionality
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +start_date+ - start date for the usage
  # * +end_date+ - end date for the usage
  # * +daily_time_period+ - array of daily time periods, hash is specified in
  #                         meter interface of design document
  # * +meter+ - array of meters
  #
  # === Outputs
  # returns hash array with single value, the hash is specified in meter interface
  # of design document (by meter) (daily_usage keys values are empty array)
  def self.usage_by_meter(start_date, end_date, daily_time_period, meter)
    date_range = {:start_date => start_date, :end_date => end_date}
    return LinearRegressionPredictor.use([date_range], daily_time_period, meter, {:meters => true }, false)
  end

  # Calculates usage, uses #use for the functionality
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +start_date+ - start date for the usage
  # * +end_date+ - end date for the usage
  # * +daily_time_period+ - array of daily time periods, hash is specified in
  #                         meter interface of design document
  # * +meter+ - array of meters
  #
  # === Outputs
  # returns hash array with single value, the hash is specified in meter interface
  # of design document (by daily time period) (daily_usage keys values are empty array)
  def self.usage_by_time(start_date, end_date, daily_time_period, meter)
    date_range = {:start_date => start_date, :end_date => end_date}
    return LinearRegressionPredictor.use([date_range], daily_time_period, meter, {}, false)
  end

  # Calculates usage, uses #use for the functionality
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +date_range+ - hash of start and end date see metering interface documentation
  # * +daily_time_period+ - array of daily time periods, hash is specified in
  #                         meter interface of design document
  # * +meter+ - array of meters
  #
  # === Outputs
  # returns hash array with single value, the hash is specified in meter interface
  # of design document (by meter) (with daily_usage arrays)
  def self.detailed_usage_by_meter(date_range, daily_time_period, meter)
    return LinearRegressionPredictor.use(date_range, daily_time_period, meter, {:meters => true }, true)
  end

  # Calculates usage, uses #use for the functionality
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +date_range+ - hash of start and end date see metering interface documentation
  # * +daily_time_period+ - array of daily time periods, hash is specified in
  #                         meter interface of design document
  # * +meter+ - array of meters
  #
  # === Outputs
  # returns hash array with single value, the hash is specified in meter interface
  # of design document (by daily usage period) (with daily_usage arrays)
  def self.detailed_usage_by_time(date_range, daily_time_period, meter)
    return LinearRegressionPredictor.use(date_range, daily_time_period, meter, {}, true)
  end

  # Calculates usage for this meter, uses #use for the functionality
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +start_date+ - start date for the usage
  # * +end_date+ - end date for the usage
  # * +daily_time_period+ - array of daily time periods, hash is specified in
  #                         meter interface of design document
  #
  # === Outputs
  # returns hash array with single value, the hash is specified in meter interface
  # of design document (by meter) (with daily_usage arrays)
  def usage_by_meter(start_date, end_date, daily_time_period)
    date_range = [{:start_date => start_date, :end_date => end_date}]
    meter = Meter.where(id: meter_id).take
    return LinearRegressionPredictor.use(date_range, daily_time_period, [meter], {:meters => true }, false)
  end

  # Calculates usage for this meter, uses #use for the functionality
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +start_date+ - start date for the usage
  # * +end_date+ - end date for the usage
  # * +daily_time_period+ - array of daily time periods, hash is specified in
  #                         meter interface of design document
  #
  # === Outputs
  # returns hash array with single value, the hash is specified in meter interface
  # of design document (by daily time period) (with daily_usage arrays)
  def usage_by_time(start_date, end_date, daily_time_period)
    date_range = {:start_date => start_date, :end_date => end_date}
    meter = Meter.where(id: meter_id).take
    return LinearRegressionPredictor.use([date_range], daily_time_period, [meter], {}, false)
  end

  #=========Internal Methods=================================================================

  # generic function to return usage in the complicated hash format specified
  # Used by all the external functions that change the variables +broken_by+
  # and +detailed+ to get the desired output
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +date_range+ - hash of start and end date see metering interface documentation
  # * +daily_time_period+ - array of daily time periods, hash is specified in
  #                         meter interface of design document
  # * +meter+ - array of meters
  # * +broken_by+ - simple hash if :meters key exists then it will output
  #                 the hash broken down by meter otherwise by daily time period
  #                 (see metering interface of design document for details)
  # * +detailed+ - boolean
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  # LinearRegressionPredictors exist for the time periods and meter
  #
  # === Outputs
  # returns hash array with single value, the hash is specified in meter interface
  # of design document
  # returns by meter if :meters key exists in +broken_by+
  # returns daily_usage breakdowns if detailed is true
  def self.use(date_range, daily_time_period, meter, broken_by, detailed)
    check_times(daily_time_period)
    check_meters(meter)

    output = [{}]
    # initialise totals
    total_usage = 0
    total_daily_usage = 0

    # two ways to return output by meter first or by daily time period first
    # they need different values in hash etc
    if broken_by[:meters] != nil
      output[0][:label] = '' #not needed
    end
    output[0][:start_date] = date_range[0][:start_date]
    output[0][:end_date] = date_range[0][:end_date]
    output[0][:unit_of_measurement] = 'kwh'  # value for all aggregations in the system

    # metering first
    if broken_by[:meters] != nil
      total_usage, total_daily_usage, output[0][:meters] = make_meter_daily_hash_array(date_range, daily_time_period, meter, detailed)
    else
      #must be broken down by daily time period
      output[0][:daily_time_periods] = make_daily_meter_hash_array(date_range, daily_time_period, meter,detailed)

      #calculate totals for each day because we haven't done that yet
      meter.each do |each_meter|
        # for whole day now whole day is time from midday to midday
        prediction = predict_whole_day(each_meter, date_range)
        # total usage is sum of all the meters total usage
        total_usage = total_usage + sum_usage(prediction)
        #if detailed breakdown needed keep sum of total for each day
        if detailed
          #no daily total usage stored
          if total_daily_usage == 0
            total_daily_usage = prediction
          else
            if !prediction.blank?
              #otherwise need to add usages for each day
              i = 0
              while i < total_daily_usage.length
                total_daily_usage[i][:usage] = total_daily_usage[i][:usage] + prediction[i][:usage]
                i = i + 1
              end
            end
          end
        end
      end
    end
    output[0][:usage] = total_usage
    if detailed
      output[0][:daily_usage] = total_daily_usage
    else
      output[0][:daily_usage] = []
    end
    return output
  end

  # makes the hash broken down by meter first (see design document metering interface)
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +date_range+ - hash of start and end date see metering interface documentation
  # * +daily_time_period+ - array of daily time periods, hash is specified in
  #                         meter interface of design document
  # * +meter+ - array of meters
  # * +detailed+ - boolean
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  # LinearRegressionPredictors exist for the time periods and meter
  #
  # === Outputs
  # returns hash array of the values for :meter in the by meter return value
  # specified in the design document metering interface
  # returns daily_usage breakdowns if detailed is true
  def self.make_meter_daily_hash_array(date_range, daily_time_periods, meters,detailed)
    total_usage = 0
    total_daily_usage = 0
    output = []
    #for each meter
    meters.each do |each_meter|
      #add the each of the meter's values to a hash to add to the array
      meter_output = {}
      meter_output[:serial] = each_meter.serial

      meter_output[:daily_time_periods] = []
      #for each daily time period
      daily_time_periods.each do |each_daily_time_period|
        #add the each of the daily time period's values to a hash to add to the array
        daily_output = {}
        if each_daily_time_period[:label] != nil
          daily_output[:label] = each_daily_time_period[:label]
        else
          daily_output[:label] = ''
        end
        daily_output[:start_time] = each_daily_time_period[:start_time]
        daily_output[:end_time] = each_daily_time_period[:end_time]

        # predict for this period (daily hash)
        prediction = predict_for_period(each_meter,
                                        each_daily_time_period[:start_time],
                                        each_daily_time_period[:end_time],
                                        date_range)
        if !prediction.blank?
          daily_output[:usage] = sum_usage(prediction)
          if detailed
            daily_output[:daily_usage] = prediction
          else
            daily_output[:daily_usage] = []
          end
        else
          daily_output[:usage] = 0
          daily_output[:daily_usage] = []
        end
        #add this daily usage period to array
        meter_output[:daily_time_periods].push(daily_output)
      end

      # add for whole day now for this meter
      prediction = predict_whole_day(each_meter, date_range)
      if !prediction.blank?
        # usage is sum of daily usages
        meter_output[:usage] = sum_usage(prediction)

        # total usage is sum of all the meters total usage
        total_usage = total_usage + meter_output[:usage]
        #if detailed is needed add the breakdown by day (and add to total breakdown)
        if detailed
          meter_output[:daily_usage] = prediction
          #no daily total usage stored yet
          if total_daily_usage == 0
            total_daily_usage = prediction
          else
            #otherwise need to add usages for each day to the total for that day
            i = 0
            while i < total_daily_usage.length
              total_daily_usage[i][:usage] = total_daily_usage[i][:usage] + prediction[i][:usage]
              i = i + 1
            end
          end
        else
          #otherwise add blank
          meter_output[:daily_usage] = []
        end
      else
        meter_output[:usage] = 0
        meter_output[:daily_usage] = []
      end
      #add hash to array of meters
      output.push(meter_output)
    end
    return total_usage, total_daily_usage, output
  end


  # makes the hash broken down by daily usage period first
  # (see design document metering interface)
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +date_range+ - hash of start and end date see metering interface documentation
  # * +daily_time_period+ - array of daily time periods, hash is specified in
  #                         meter interface of design document
  # * +meter+ - array of meters
  # * +detailed+ - boolean
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  # LinearRegressionPredictors exist for the time periods and meter
  #
  # === Outputs
  # returns hash array of the values for :each_daily_time_periods in the by meter return value
  # specified in the design document metering interface
  # returns daily_usage breakdowns if detailed is true
  def self.make_daily_meter_hash_array(date_range, daily_time_periods, meters,detailed)
    output = []
    daily_time_periods.each do |each_daily_time_period|
      #create hash to store this daily time periods values
      daily_output = {}
      if each_daily_time_period[:label] != nil
        daily_output[:label] = each_daily_time_period[:label]
      else
        daily_output[:label] = ''
      end
      daily_output[:start_time] = each_daily_time_period[:start_time]
      daily_output[:end_time] = each_daily_time_period[:end_time]
      # create totals for the daily period
      daily_time_period_usage = 0
      daily_time_period_daily_usage = 0

      daily_output[:meters] = []
      # for each meter
      meters.each do |each_meter|
        #create hash to store this meter's values
        meter_output = {}
        meter_output[:serial] = each_meter.serial
        # predict for this period (daily hash)
        prediction = predict_for_period(each_meter,
                                        each_daily_time_period[:start_time],
                                        each_daily_time_period[:end_time],
                                        date_range)
        # add usage for all days
        meter_output[:usage] = sum_usage(prediction)
        if !prediction.blank?
          # add usage to total for the time period
          daily_time_period_usage = daily_time_period_usage + meter_output[:usage]
          # if we need to add usage broken down by day (also calculate totals per day for use later)
          if detailed
            meter_output[:daily_usage] = prediction
            #if no totals yet then set
            if daily_time_period_daily_usage == 0
              daily_time_period_daily_usage = prediction
            else
              #otherwise need to add usages for each day
              i = 0
              while i < daily_time_period_daily_usage.length
                daily_time_period_daily_usage[i][:usage] =
                    daily_time_period_daily_usage[i][:usage] + prediction[i][:usage]
                i = i + 1
              end
            end
          else
            # if not needed set to empty array
            meter_output[:daily_usage] = []
          end
        else
          meter_output[:daily_usage] = []
        end
        # add hash to array of meters
        daily_output[:meters].push(meter_output)
      end
      # add usage and detailed if required
      daily_output[:usage] = daily_time_period_usage
      if detailed
        daily_output[:daily_usage] = daily_time_period_daily_usage
      else
        daily_output[:daily_usage] = []
      end
      #add this daily usage period to array
      output.push(daily_output)
    end
    return output
  end

  # Calculates usage for daily time period corresponding to the whole day
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +meter+ - single meter
  # * +date_range+ - hash of start and end date see metering interface documentation
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  # LinearRegressionPredictors exist for the time periods and meter
  #
  # === Outputs
  # returns predicted usage in format specified in metering interface documentation
  # for :daily_usage
  def self.predict_whole_day(meter, date_range)
    #midday specifies start of a day (inbuilt) used to denote entire day
    return predict_for_period(meter, midday, midday, date_range)
  end

  # Calculates usage for daily time period corresponding to the whole day
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +meter+ - single meter
  # * +start_time+ - start time for daily time period
  # * +end_time+ - end  time for daily time period
  # * +date_range+ - hash of start and end date see metering interface documentation
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  # LinearRegressionPredictors exist for the time period and meter
  #
  # === Outputs
  # returns predicted usage in format specified in metering interface documentation
  # for :daily_usage
  def self.predict_for_period(meter, start_time, end_time, date_range)
    #retrieve predictor to predict with
    predictor = LinearRegressionPredictor.where(meter_id: meter.id,
                                                start_time: start_time,
                                                end_time: end_time).take
    if predictor.blank?
      prediction = []
    else
      prediction = predictor.daily_usage(date_range[0][:start_date], date_range[0][:end_date])
    end
    return prediction
  end

  # Sums :daily_usage array (see metering interface documentation for reference)
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +daily_usage+ - array of :daily_usage hashes
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  #
  # === Outputs
  # returns sum of the :usage values in the hash array
  def self.sum_usage(daily_usage)
    total = 0
    if daily_usage.blank?
      return 0
    end
    daily_usage.each do |hash|
      total = total + hash[:usage]
    end
    return total
  end

  # creates :usage hash array between start and end date
  # (see metering interface documentation for reference)
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +start_date+ - start date
  # * +end_date+ - end date
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  # end date is after start date
  #
  # === Outputs
  # returns :usage hash array between start and end date inclusive
  def daily_usage(start_date, end_date)
    #generate dates between start and end inclusive
    current_date = start_date
    dates = [current_date]
    while current_date < end_date do
      current_date = current_date + 1
      dates.push(current_date)
    end
    # create array of usages (per day)
    usages = []
    dates.each do |date|
      hash = {}
      hash[:date] = date
      hash[:usage] = predict(date)
      usages.push(hash)
    end

    return usages
  end

  # predict the usage for a date
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +date+ -  date to predict for
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  #
  # === Outputs
  # returns the usage calculated for the day
  def predict(date)
    offset_integer = LinearRegressionPredictor.date_to_offset_integer(date)
    usage = a + (b * offset_integer)
    #need to return floats for front end to use (not Big Decimal as is stored)
    usage = usage.to_f
    return usage
  end

  # fit a line to the data using linear regression
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +daily_usages+ -  array of daily usage values
  # * +dates+ -  array of dates
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  # arrays have the same length
  #
  # === Outputs
  # returns y intercept and the slope of the line (fully describes the line)
  def self.make_prediction(daily_usages, dates)
    if daily_usages.length > 1
      # map days(Date object) to integer offsets from the reference date
      offset_integers = dates_to_offset_integers(dates)

      # use predictor gem to create the regression and return the values
      linefitter = LineFit.new
      linefitter.setData(offset_integers, daily_usages)
      intercept, slope = linefitter.coefficients
      return intercept, slope
      #zero slope if only one days worth of data, line height is height of point
    elsif daily_usages.length == 1
      return daily_usages[0], 0.0
    else
      raise "no data in make_prediction"
    end
  end


  # maps dates to integer offsets from a set date so the
  # linefit gem can use the data
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +dates+ -  array of dates
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  #
  # === Outputs
  # returns array of integers (offsets)
  # error if not array
  def self.dates_to_offset_integers(dates)
    # make sure we have an array being passed
    # defer checking for dates to the function we call so not to do it twice
    if not dates.is_a?(Array)
      raise "dates_to_offset_integers: argument is not an Array"
    end

    output = []
    # loop through the array converting to integers for output
    dates.each do |date|
      output.push(date_to_offset_integer(date))
    end
    return output
  end


  # maps a date to  an integer offsets from a set date
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +dates+ -  array of dates
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  #
  # === Outputs
  # returns array of integers (offsets)
  # error if not Date type
  def self.date_to_offset_integer(date)
    #make sure we have a date being passed
    if not date.is_a?(Date)
      raise "date_to_offset_integer: argument is not a date"
    end
    output = (date - REFERENCE_DATE).to_i
    return output
  end


  # maps integer offsets from a set date to dates
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +offset_integers+ -  array of integers (offsets)
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  #
  # === Outputs
  # returns array of integers (offsets)
  # error if not array
  def self.offset_integers_to_dates(offset_integers)
    # make sure we have an array being passed
    # defer checking for dates to the function we call so not to do it twice
    if not offset_integers.is_a?(Array)
      raise "offset_integers_to_dates: argument is not an Array"
    end

    output = []
    # loop through the array converting to integers for output
    offset_integers.each do |offset_integer|
      output.push(offset_integer_to_date(offset_integer))
    end
    return output
  end

  # maps integer offset from a set date to a  date
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +offset_integer+ -  integer (offset)
  #
  # === Preconditions
  # It is expected that all the inputs are of the correct type
  #
  # === Outputs
  # returns date
  # raises error if type is not an integer
  def self.offset_integer_to_date(offset_integer)
    #make sure we have a date being passed
    if not offset_integer.is_a?(Integer)
      raise "offset_integer_to_date: argument is not an integer"
    end
    output = (REFERENCE_DATE + offset_integer)
    return output
  end

  # check if input is array of time periods (metering interface design document)
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +daily_time_periods+ -  array of daily_time periods (see design)
  #
  # === Outputs
  # checks each daily_time period
  # raises error is not an array
  def self.check_times(daily_time_periods)
    if daily_time_periods.is_a?(Array)
      daily_time_periods.each do |daily_time_period|
        check_time(daily_time_period)
      end
    else
      raise "daily time periods is not an array"
    end
  end

  # check if input is a daily time period (metering interface design document)
  #
  # Author: Peter McNamara
  #
  # ==== Inputs
  # * +daily_time_period+ -  array of daily_time period (see design)
  #
  # === Outputs
  # raises error if :start_time value is not a Time
  # raises error if :end_time value is not a Time
  # raises error if :start_time value is greater than :end_time
  def self.check_time(daily_time_period)
    if not daily_time_period[:start_time].is_a?(Time)
      raise "bad daily time period - start time not a time"
    end
    if not daily_time_period[:end_time].is_a?(Time)
      raise "bad daily time period - end time not a time"
    end
  end

  # check if input is an array of Meters return error if it is not
  def self.check_meters(meters)
    if meters.is_a?(Array)
      meters.each do |meter|
        check_meter(meter)
      end
    else
      raise "not an array of meters"
    end
  end

  # check if input is a Meter return error if it is not
  def self.check_meter(meter)
    if not meter.is_a?(Meter)
      raise "not a meter"
    end
  end

  #simple function to return the time representing noon (midday)
  def self.midday
    Time.new(2000,'jan',1,12,0)
  end
end
