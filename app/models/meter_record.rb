class MeterRecord < ActiveRecord::Base
# Shared methods for the Mtering subsystem
  include Metering

# MeterRecords belong to Meters
  belongs_to :meter


################################################################################
# Importing NEM12
#

# Imports NEM12, reads the given directory, and imports any
# NEM12 records found, provided the records is for a Meter
# in the received array of Meters
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +directory+ - a directory containing NEM12 data
# * +meters+ - an array of Meter objects
#
# === Outputs
# None
  def self.import_nem12 directory, meters

    imported_meters = Set.new []

#   Check that the directory exists, error if it doesn't
    return directoryNotFoundError directory unless directory and Dir.exist? directory
#   Check that only Meters exist in the meters array
    return badMeterError unless is_array_of_meters meters
#   The arguments are good, run the import

#   Get a hash of meter serial/ids.
#   If the record isn't in the whitelist, it doesn't get in.
    whitelist = Meter.whitelist meters

#   We want to keep track of the date range so that we can aggregate easily
    start_date = Date.tomorrow
    end_date = Date.today - 40.years

#######################################################
#   Let's get some metrics on this

    #metric_start = Time.now()

#   Create a temporary table to store the import before
#   moving new values to meter records
    temptbl = SecureRandom.base64(10)
    sql = "
      CREATE TABLE
        \"#{temptbl}\" AS
        (
          SELECT
            *
          FROM
            meter_records
          WHERE
            false
        );
      "

    ##logger.info sql
    result = ActiveRecord::Base.connection.raw_connection.exec sql

#   TODO check for bad filename, add to return errors

#   Check each file in the directory
    Dir.glob("#{directory}/*.csv") do |filename|
      ##logger.info "Reading #{filename}"
#     Initialise some stuff
      nmi = ""
      serial = ""
      interval = 1
      meter_records = []

      line = 0

#     Read each line of the file
      file = File.open(filename, 'r')
      while !file.eof?
        line = line + 1
        record = file.readline.split(",")
#       Check what kind of reord this is

#       TODO test that record[0] exists
        identifier = record[0]
        case identifier
          when '100'
#TODO       Anything?
          when '200'
            valid_200_record = false
#           Validate the record
            if validate_200_record record

              # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
              # logger.info ""
              # logger.info "Valid 200 record (#{line})"
              # logger.info ""
              # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

#             Guard using whitelist and meter serial number
#             Maybe quicker just to let this stuff happen
              serial = record[6]
              ##logger.info "Reading valid 200 Record for serial #{serial}"
              if whitelist.value? serial
                # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                # logger.info "200 Record is in whitelist"
                # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                valid_200_record = true
#               Data for this meter will be imported
                nmi = record[1]
                register = record[3]
                interval = record[8].to_i # Num of minutes per interval
                ##logger.info "Setting interval to #{interval}"
                uom = record[7] # Unit of Measurement
              else
                # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                # logger.info "200 Record is NOT in whitelist"
                # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
              end

            else
#             This is not a valid 200 record
              # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
              # logger.info ""
              # logger.info "Invalid 200 record (#{line})"
              # logger.info ""
              # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            end
          when '300'

            #logger.info "Looking at a 300 Record"

#           Now validate the 300 record
            if valid_200_record then
              #logger.info "200 Record was validated, trying 300 record"
              validate_300_record record, interval
            end

            if valid_200_record and validate_300_record record, interval

              # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
              # logger.info ""
              # logger.info "Valid 300 record (#{line})"
              # logger.info ""
              # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

#             This is what we really need the guard for
              if whitelist.value? serial

#               Add this meter to the set of meters that have had data imported

                imported_meters.add( whitelist.key(serial) )

                ##logger.info "Reading 300 Record"
#               Write the record
                usage = record[2...2+minutes_in_day/interval].map { |s| s.to_f }
                date = record[1].to_date

#               Keep track of the earliest and latest date
#               so that we know what date range to aggregate
                start_date = date unless date >= start_date
                end_date = date unless date <= end_date

#               These are the values that will be inserted
                meter_records.push(
                  "(
                    #{whitelist.key(serial)},
                    '#{register}',
                    '#{date}',
                    #{interval},
                    '#{uom}',
                    ARRAY#{usage}
                  )"
                )
              end
            else
              # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
              # logger.info ""
              # logger.info "Invalid 300 record (#{line})"
              # logger.info ""
              # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            end
        end
      end



#     Mass insert the records for this file
# =>  TODO  / This doesn't return anything.
#           / We would like to return enough information to give the user or log
#           / a good indication of what the import managed to do
#           / -- i.e., how many records were inserted for each meter,
#           / how many records were ignored, etc.
#           / This is a problem, because the postgresql rule on meter_records,
#           / ignore_duplicate_meter_records, won't allow a return value, and
#           / regular inserts won't either while that rule is in place.
#           / Possibly the rule can be fixed up? Possibly we can use a different
#           / strategy to find that information?
      if ( meter_records.length > 0 )
#       This doesn't return anything :(

        sql = "INSERT INTO \"#{temptbl}\"
                (
                  meter_id,
                  register,
                  date,
                  interval,
                  unit_of_measurement,
                  usage
                )
              VALUES
                #{meter_records.join(", ")};"

        ##logger.info sql

#       Run the query
#       Catch the exception in case anything goes wrong
        begin

          result = ActiveRecord::Base.connection.raw_connection.exec sql

      #############
      #   Now move contents of temp table into meter_records
      #   without duplicating existing records
          sql = "
            INSERT
              INTO
                meter_records

                (
                  meter_id,
                  register,
                  date,
                  interval,
                  unit_of_measurement,
                  usage
                )

              (
                SELECT
                  meter_id,
                  register,
                  date,
                  interval,
                  unit_of_measurement,
                  usage

                FROM
                  \"#{temptbl}\" as T
                WHERE
                  NOT EXISTS
                  (
                      SELECT
                        1
                      FROM
                        meter_records
                      WHERE
                        meter_id = T.meter_id
                      AND
                        date = T.date
                      AND
                        register = T.register
                  )
              )
            RETURNING meter_id;
            "
      #   #logger.info sql
          result = ActiveRecord::Base.connection.raw_connection.exec sql
      #   log_pg_result result
      #
      ###########################
          rescue
          logger.info "#####################################################################"
          logger.info "###"
          logger.info "### Notice: Exception Caught. There was a problem importing meter data."
          logger.info "###"
          logger.info "#####################################################################"
        end

      end

    end

#   Remove the temp table
    sql = "DROP TABLE IF EXISTS \"#{temptbl}\";"
    result = ActiveRecord::Base.connection.raw_connection.exec sql

#   Get the time periods -- used to create aggregations -- from Billing
    daily_time_periods = Meter.get_daily_time_periods meters

    date_ranges = [ { :start_date => start_date, :end_date => end_date } ]

#   Collect the meters that have ACTUALLY BEEN AFFECTED to pass on to Aggregations and Predictors
    imported_meters = imported_meters.collect {|id| Meter.find(id) }

#   Now create the aggregations for these Meters over the relevant date range
    MeterAggregation.aggregate_and_store date_ranges, daily_time_periods, imported_meters

#   Notify other subsystems that there is new data in the system
    Meter.notify_new_data imported_meters, date_ranges

#   Return some stuff -- this to be superseded by actual real information
#   See comments above the sql query in this method
    meters = {}
    whitelist.each do |id, serial|
      meters[serial] = 1
    end

    errors = []

#    return sql

    return {
      :meters => meters,
      :errors => errors
    }

  end




private

################################################################################
# Validating records


# Validates a 200 record
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +record+ - array, NEM12 200 record
#
# === Outputs
# Returns true if the 200 record is ok, false if not
  def self.validate_200_record record

#   10 values in the record
    return false unless record.length == 10
    ##logger.info "Validated Record length"


#   NMI char(10)
    return false unless record[1].length == 10
    ##logger.info "Validated NMI length"


#   NMIConfiguration varchar(240)
    return false unless is_varchar record[2], 240
    ##logger.info "Validated NMIConfiguration"


#   RegisterID varchar(10)
    return false unless is_varchar record[3], 10
    ##logger.info "Validated RegisterID"


#   NMISuffix == char(2)
    return false unless record[4].length == 2
    ##logger.info "Validated NMISuffix"


#   MDMDataStreamIdentifier chr(2)
    return false unless record[5].length == 2
    ##logger.info "Validated MDMDataStreamIdentifier"


#   Meter Serial varchar(12)
    return false unless is_varchar record[6], 12
    ##logger.info "Validated Meter Serial"


#   UOM varchar(5)
    return false unless is_varchar record[7], 5
    ##logger.info "Validated UOM"


#   UOM is a valid nem12 unit of measurement
    return false unless is_nem12_uom record[7]
    ##logger.info "Validated unit of measurement"


#   Interval is a valid nem12 time interval
    return false unless is_nem12_interval record[8]
    ##logger.info "Validated Interval"

#   Next Scheduled Read Date is not required
    return false unless record[9].blank? or is_valid_date record[9]
#    #logger.info "Validated Scheduled Read Date"

#   Good to go
    # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    # logger.info ""
    # logger.info "Validated 200 record"
    # logger.info ""
    # logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    return true
  end



# Validates a 200 record
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +record+ - array, NEM12 200 record
#
# === Outputs
# Returns true if the 300 record is ok, false if there's something wrong with it
  def self.validate_300_record record, interval
    #logger.info "Validating 300 with interval : #{interval}"
#   Validate the date
    return false unless is_valid_date record[1] #Date
    # logger.info "  300 Date Validated"


#   Usage values, floats
    last_usage_index = minutes_in_day / interval + 1
    (2..last_usage_index).each do |index|
      if nan record[index] then return false end
    end

    # logger.info "  300 Usage Validated"



#   Quality Method varchar(3)
    return false unless is_varchar record[last_usage_index+1], 3

    # logger.info "  300 Quality Method Validated"


#   These following values are totally inconsequential to the syste,
#    so they're not checked


#   Reason Code, integer less than 100
    if nan record[last_usage_index+2] or record[last_usage_index+2].to_i > 99
     #return false
    end

#
#   These following, commented out, validations are inconsequential to the system
#

#   Reason Description varchar(240)
    #return false unless is_varchar record[last_usage_index+3], 240
    # logger.info "  300 Reason Description Validated    "

#   Update Time, datetime
    #return false unless is_date record[last_usage_index+4]
    # logger.info "  300 Update Time Validated"

#   MSATSLoadDateTime datetime
    #return false unless is_date record[last_usage_index+5]
    # logger.info "  300 MSATSLoadDateTime Validated"

#   Good to go
    return true
  end


# Returns true if value is a valid nem12 time interval
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +value+ a string read from NEM12
#
# === Outputs
# Returns true if value's valid, false if not
  def self.is_nem12_interval value
    return false unless nem12_intervals.include?(value.to_i)
    return true
  end

# Returns true if value is a valid nem12 unit
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +value+ a string read from NEM12
#
# === Outputs
# Returns true if value's valid, false if not
  def self.is_nem12_uom value
    return false unless nem12_uom.include?(value.downcase)
    return true
  end

# Returns true if the str is NOT a number, false if it is
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +value+ a string read from NEM12
#
# === Outputs
# Returns true if value's valid, false if not  def self.nan str
    str !~ /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/
  end

# Returns true if d is a valid date before tomorrow
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +value+ a string read from NEM12
#
# === Outputs
# Returns true if value's valid, false if not  def self.is_valid_date d
    begin
      #logger.info d
      date = d.to_date
      #logger.info date
      return false unless date < Date.tomorrow
    rescue
      #logger.info d
      return false
    end
    return true
  end

# Validates a date
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +value+ a string read from NEM12
#
# === Outputs
# Returns true if value's valid, false if not  def self.is_date d
    begin
      date = d.to_date
    rescue
      return false
    end
    return true
  end



# Returns true if 0 < value.length < length
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +value+ a string read from NEM12
#
# === Outputs
# Returns true if value's valid, false if not  def self.is_varchar value, length
  return false unless value.length <= length and value.length > 0
    return true
  end

# Gets an array of valid NEM12 intervals
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +value+ a string read from NEM12
#
# === Outputs
# Returns an array of valid NEM12 intervals
  def self.nem12_intervals
    return [1, 5, 10, 15, 30]
  end


#
# End Validating records
########################


end
