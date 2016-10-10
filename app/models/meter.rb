require 'rubygems'
require 'active_support'
require 'active_support/core_ext/numeric/time'
require 'active_support/time'

class Meter < ActiveRecord::Base
# Include shared methods
  include Metering

  belongs_to :billing_site
  validates :serial, length: { minimum: 2, maximum: 12 }

  validates :nmi, length: { is: 10 }

  has_many :meter_records, dependent: :destroy
  has_many :meter_aggregations, dependent: :destroy
  has_many :meter_predictors, dependent: :destroy




# Overrides inherited destroy method so that only a few, as opposed to
# potentially thousands, of database calls are made.
# Permanently destroys the Meter and its subordinate objects.
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# None
#
# === Outputs
# None
#
  def destroy
    destroy_meter_records
    destroy_meter_aggregations
    destroy_meter_predictors
    sql = "
      DELETE
        FROM
          meters
        WHERE
          id = #{id}
    "
  #logger.info " Delete Meter >>>>>>>>>>>>>>>>>>>>> #{sql}"
  result = ActiveRecord::Base.connection.raw_connection.exec sql
  end



# Permanently destroys all MeterPredictors belonging to this Meter
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# None
#
# === Outputs
# None
#
  def destroy_meter_predictors
    sql = "
      CREATE OR REPLACE FUNCTION
          deleteMeterPredictors(_mid integer)
        RETURNS
          boolean
        LANGUAGE plpgsql AS $$
          DECLARE
            tbl character varying;
            actable character varying;
          BEGIN
            FOR
              tbl, actable IN
                SELECT DISTINCT
                  LOWER(REGEXP_REPLACE(actable_type, '(.)([A-Z])', '\\1_\\2', 'g')) || 's' as tbl,
                  actable_type AS actable
              FROM
                meter_predictors
              LOOP
                EXECUTE '
              DELETE
                FROM
                  ' || tbl || '
                WHERE
                  id IN
                    (
                      SELECT * FROM (
                        SELECT
                            ' || tbl || '.id
                          FROM
                            ' || tbl || '
                          LEFT JOIN
                            meter_predictors
                          ON
                            meter_predictors.actable_id = ' || tbl || '.id
                          WHERE
                            meter_predictors.meter_id = ' || _mid || '
                          AND
                            meter_predictors.actable_type = ''' || actable || '''
                      ) AS t
                    )
                ';
              END LOOP;
            return true;
          END;
        $$;

        SELECT deleteMeterPredictors(#{id});

        DELETE
          FROM
        meter_predictors
          WHERE
        meter_id = #{id};
      "
    #logger.info " Delete Predictors >>>>>>>>>>>>>>>>>>>>> #{sql}"
    result = ActiveRecord::Base.connection.raw_connection.exec sql
  end


# Permanently destroys all MeterAggregations belonging to this Meter
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# None
#
# === Outputs
# None
#
  def destroy_meter_aggregations
    sql = "
          DELETE
            FROM
          meter_aggregations
            WHERE
          meter_id = #{id}"
    #logger.info " Delete Aggregations >>>>>>>>>>>>>>>>>>>>> #{sql}"
    result = ActiveRecord::Base.connection.raw_connection.exec sql
  end


# Permanently destroys all MeterRecords belonging to this Meter
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# None
#
# === Outputs
# None
#
  def destroy_meter_records
    sql = "
          DELETE
            FROM
          meter_records
            WHERE
          meter_id = #{id}"
    #logger.info " Delete Records >>>>>>>>>>>>>>>>>>>>> #{sql}"
    result = ActiveRecord::Base.connection.raw_connection.exec sql
  end



# Returns the class that is being used as a Predictor.
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# none
#
# === Outputs
# Returns a subclass of MeterPredictor -- LinearRegressionPredictor
  def self.predictor
    return LinearRegressionPredictor
  end


################################################################################
# Interfaces to Billing
#

# Returns an array of Daily Time Periods
# This method calls the Billing subsystem to get DTPs. Every other location
# in the Metering subsystem that requires a call to get DTPs should come
# through here.
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# none
#
# === Outputs
# Returns a subclass of MeterPredictor (LinearRegressionPredictor)
  def self.get_daily_time_periods meters
    begin
      return RetailPlan.daily_time_periods meters
    rescue
      logger.info "#####################################################################"
      logger.info "###"
      logger.info "### Notice: There was a problem with method 'RetailPlan.daily_time_periods'"
      logger.info "###"
      logger.info "#####################################################################"
      return []
    end
  end

# Called whenever new MeterRecords enter the system.
# This method should call anything that needs to know about new data entering
# the system.
# It would be preferable to add a receive_notification method to
# other subsystems rather than call update... directly.
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# None
#
# === Outputs
# None
  def self.notify_new_data meters, date_ranges
    begin
      return BillingSite.update_generated_invoice meters, date_ranges
    rescue
      logger.info "#####################################################################"
      logger.info "###"
      logger.info "### Notice: There was a problem with method 'BillingSite.update_generated_invoice'"
      logger.info "###"
      logger.info "#####################################################################"
    end
  end

#
# End Interfaces to Billing
################################################################################



################################################################################
# Import NEM12 Interface
#

# Interface to import data to the system.
# All work is done by MeterRecord.import_nem
# Reads the specified directory for NEM12 files, and imports any records
# in those files, provided that those records are for Meters specified in the
# parameter meters.
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +directory+ - string specifying the location of a directory to be scanned
# for NEM12 files
# * +meters+ - array of Meters. Record will only be imported for Meters
# specified here.
#
# === Outputs
# {}
  def self.import_nem12 directory, meters
    return MeterRecord.import_nem12 directory, meters
  end
#
# End Import NEM12 Interface
################################################################################





################################################################################
# Usage Interface
#




# Instance interfaces
#
# Each of these methods passing a call to its static counterpart
# by inserting the current instance into the required meters array argument

# Methods for actual usage


# Calculates usage for this meter
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def usage_by_meter date_ranges, daily_time_periods
    return Meter.usage_by_meter date_ranges, daily_time_periods, [self]
  end

# Calculates usage for this meter, organised by Daily Time Period
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def usage_by_time date_ranges, daily_time_periods
    return Meter.usage_by_time date_ranges, daily_time_periods, [self]
  end

# Calculates detailed usage (including daily usage totals) for this meterPeriod
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def detailed_usage_by_meter date_ranges, daily_time_periods
    return Meter.detailed_usage_by_meter date_ranges, daily_time_periods, [self]
  end

# Calculates detailed usage (including daily usage totals) for this meter,
# organised by Daily Time Period
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def detailed_usage_by_time date_ranges, daily_time_periods
    return Meter.detailed_usage_by_time date_ranges, daily_time_periods, [self]
  end

# End Methods for actual usage


# Methods for predicted usage

  def predicted_usage_by_meter date_ranges, daily_time_periods
    return Meter.predicted_usage_by_meter date_ranges, daily_time_periods, [self]
  end

  def predicted_usage_by_time date_ranges, daily_time_periods
    return Meter.predicted_usage_by_time date_ranges, daily_time_periods, [self]
  end

# TODO add this method to SDD
  def detailed_predicted_usage_by_meter date_ranges, daily_time_periods
    return Meter.detailed_predicted_usage_by_meter date_ranges, daily_time_periods, [self]
  end

# TODO add this method to SDD
  def detailed_predicted_usage_by_time date_ranges, daily_time_periods
    return Meter.detailed_predicted_usage_by_time date_ranges, daily_time_periods, [self]
  end

# End Methods for predicted usage

#
# End Instance interfaces




# Class (static) interfaces
#

# Methods for actual usage

# Calculates detailed usage for the requested
# Meters
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
# * +meters+ - an array of Meter objects
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def self.usage_by_meter date_ranges, daily_time_periods, meters
    return Meter.usage date_ranges, daily_time_periods, meters, :meter
  end

# Calculates usage for the requested Meters, organised by Daily Time Period
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
# * +meters+ - an array of Meter objects
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def self.usage_by_time date_ranges, daily_time_periods, meters
    return Meter.usage date_ranges, daily_time_periods, meters, :time
  end

# Calculates detailed usage (including daily usage totals) for the requested
# Meters
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
# * +meters+ - an array of Meter objects
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def self.detailed_usage_by_meter date_ranges, daily_time_periods, meters
    return Meter.usage date_ranges, daily_time_periods, meters, :meter, true
  end

# Calculates detailed usage (including daily usage totals) for the requested
# Meters, organised by Daily Time Period
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
# * +meters+ - an array of Meter objects
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def self.detailed_usage_by_time date_ranges, daily_time_periods, meters
    return Meter.usage date_ranges, daily_time_periods, meters, :time, true
  end

# End Methods for actual usage


# Methods for predicted usage

# Requests usage data, for the requested meters, from a MeterPredictor
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
# * +meters+ - an array of Meter objects
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def self.predicted_usage_by_meter date_ranges, daily_time_periods, meters
    usages = []
    date_ranges.each do |date_range|
      usages = usages + ( Meter.predictor.usage_by_meter date_range[:start_date], date_range[:end_date], daily_time_periods, meters )
    end
    return usages
  end

# Requests usage data organised by Daily Time Period, for the requested meters,
# from a MeterPredictor
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
# * +meters+ - an array of Meter objects
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def self.predicted_usage_by_time date_ranges, daily_time_periods, meters
    usages = []
    date_ranges.each do |date_range|
      usages = usages + ( Meter.predictor.usage_by_time date_range[:start_date], date_range[:end_date], daily_time_periods, meters )
    end
    return usages
  end

# Requests detailed usage data (including daily totals), for the requested
# meters, from a MeterPredictor
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
# * +meters+ - an array of Meter objects
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def self.detailed_predicted_usage_by_meter date_ranges, daily_time_periods, meters
    usages = []
    date_ranges.each do |date_range|
      usages = usages + ( Meter.predictor.detailed_usage_by_meter [date_range], daily_time_periods, meters )
    end
    return usages
#    return Meter.predictor.detailed_usage_by_meter date_ranges, daily_time_periods, meters
  end

# Requests detailed usage data (including daily totals), organised by Daily Time
# Period, for the requested meters, from a MeterPredictor
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
# * +meters+ - an array of Meter objects
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def self.detailed_predicted_usage_by_time date_ranges, daily_time_periods, meters
    usages = []
    date_ranges.each do |date_range|
      usages = usages + ( Meter.predictor.detailed_usage_by_time [date_range], daily_time_periods, meters )
    end
    return usages
#    return Meter.predictor.detailed_usage_by_time date_ranges, daily_time_periods, meters
  end

# End Methods for predicted usage







# Trims Date Ranges to a more manageable range.
# Note that this functionality has been disabled.
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +meters+ - an array of Meter objects
#
# === Outputs
# returns a array of date ranges
  def self.trim_date_ranges date_ranges, meters
    # earliest_date = Date.current unless earliest_date = meters_first_record_date meters
    # date_ranges.each do |date_range|
    #   if date_range[:start_date] < earliest_date then date_range[:start_date] = earliest_date end
    # end
    return date_ranges
  end


# Performs an aggregation on the requested Meters, and for the time periods and
# date ranges given
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
# * +meters+ - an array of Meter objects
#
# === Outputs
# None
  def self.reaggregate date_ranges, daily_time_periods, meters

    if ( date_ranges.empty? or daily_time_periods.empty? or meters.empty? ) then return end


    meter_ids = meters.map { |m| m.id }
    dtps_where = daily_time_periods.map{|dtp| "          ( start_time = '#{dtp[:start_time]}' AND end_time = '#{dtp[:end_time]}' )\n"}

    t_queries = []
    r_queries = []
    a_queries = []


    date_ranges_where = []

    date_ranges.each do |date_range|

#     Used in T, Records R, Aggregations A
      date_range_select_as = \
          "        CAST('#{date_range[:start_date]}' AS date) AS start_date, \n" + \
          "        CAST('#{date_range[:end_date]}' AS date) AS end_date \n"
      date_range_where = "       ( date >= '#{date_range[:start_date]}' AND date <= '#{date_range[:end_date]}' )\n"
      date_ranges_where.push date_range_where

      meters.each do |meter|
        daily_time_periods.each do |dtp|

#       Write SQL to create a result set, T, containing all the required
#       combinations of date range, daily time period / meter
        t_queries.push(
          "\n    ( \n" + \
          "    SELECT \n" + \
          "        #{meter.id} AS meter_id, \n" + \
          "        TO_CHAR(TIMESTAMP '#{dtp[:start_time]}', 'HH24:MI:SS') AS start_time, \n" + \
          "        TO_CHAR(TIMESTAMP '#{dtp[:end_time]}', 'HH24:MI:SS') AS end_time, \n" + \
                   date_range_select_as + \
          "    ) \n"
        )
        end

      end

#     Write SQL queries to count Records
      r_queries.push (
        "\n    (\n" + \
        "    SELECT\n" + \
        "        meter_id,\n" + \
        "        COUNT(date) AS records,\n" + \
                 date_range_select_as + \
        "      FROM\n" + \
        "        meter_records\n" + \
        "      WHERE\n" + \
        "        meter_id = ANY('{" + \
                 meter_ids.join(",") + \
                 "}'::int[])\n" + \
        "      AND\n" + \
                 date_range_where + \
        "      GROUP BY\n" + \
        "        meter_id, start_date, end_date\n" + \
        "    )\n"
      )

#     Write SQL queries to count Aggregations
      a_queries.push (
        "\n    (\n" + \
        "    SELECT\n" + \
        "        TO_CHAR(start_time,'HH24:MI:SS') AS start_time,\n" + \
        "        TO_CHAR(end_time,'HH24:MI:SS') AS end_time,\n" + \
        "        COUNT(date) AS aggregations,\n" + \
        "        meter_id,\n" + \
                 date_range_select_as + \
        "      FROM\n" + \
        "        meter_aggregations\n" + \
        "      WHERE\n" + \
        "        meter_id = ANY('{" + \
                 meter_ids.join(",") + \
                 "}'::int[])\n" + \
        "      AND\n" + \
                date_range_where + \
        "      AND\n" + \
        "        (\n" + \
                 dtps_where.join("      OR\n") + \
        "        )\n" + \
        "      GROUP BY meter_id, start_time, end_time\n" + \
        "    )\n"
      )


    end


#   Now construct the structure of the query
#   and add our temp table, record and aggregation queries to it
    sql = "\nSELECT\n" + \
    "    TR.meter_id,\n" + \
    "    TR.start_date,\n" + \
    "    TR.end_date,\n" + \
    "    TR.start_time,\n" + \
    "    TR.end_time,\n" + \
    "    TR.records,\n" + \
    "    COALESCE ( A.aggregations, 0 ) AS aggregations\n" + \
    "\n  FROM\n" + \
    "  (\n" + \

#   Temp table
    "SELECT \n\n" + \
    "    T.meter_id, \n" + \
    "    T.start_date, \n" + \
    "    T.end_date, \n" + \
    "    T.start_time, \n" + \
    "    T.end_time, \n" + \
    "    COALESCE ( R.records, 0 ) AS records \n" + \
    "\n  FROM  \n\n" + \
    "-- Create temporary table, T, storing all the required\n" + \
    "-- combinations of date range, daily time period / meter\n\n" + \
    "  (\n" + \
    t_queries.join("\n    UNION\n") + \
    "  ORDER BY start_date, end_date, start_time, end_time, meter_id\n" + \

    "\n) T -- all possible combinations of date range, daily time period and meter\n" + \


#   Add the number of records
    "\nLEFT JOIN\n\n" + \
    "(\n\n" + \
    "-- Join the number of Records for each combination\n" + \
    r_queries.join("\n    UNION\n") + \

    "    ORDER BY\n" + \
    "      start_date, end_date, meter_id\n" + \

    ") R -- number of records for each combination\n" + \
    "  ON\n" + \
    "    T.meter_id = R.meter_id\n" + \
    "  AND\n" + \
    "    T.start_date = R.start_date\n" + \
    "  AND\n" + \
    "    T.end_date = R.end_date\n" + \
    "  ORDER BY \n" + \
    "    start_date,\n" + \
    "    end_date, \n" + \
    "    start_time,\n" + \
    "    end_time,\n" + \
    "    meter_id\n" + \
    ") TR\n\n" + \

#   Add the number of aggregatons
    "\nLEFT JOIN\n\n" + \
    "(\n\n" + \
    "-- Join the number of Aggregations for each combination\n" + \
    a_queries.join("\n    UNION\n") + \

    ") A -- number of aggregations for each combination\n" + \
    "  ON\n" + \
    "    TR.meter_id = A.meter_id\n" + \
    "  AND\n" + \
    "    TR.start_date = A.start_date\n" + \
    "  AND\n" + \
    "    TR.end_date = A.end_date\n" + \
    "  AND\n" + \
    "    TR.start_time = A.start_time\n" + \
    "  AND\n" + \
    "    TR.end_time = A.end_time\n" + \
    "  ORDER BY\n" + \
    "    start_date,\n" + \
    "    end_date,\n" + \
    "    start_time,\n" + \
    "    end_time,\n" + \
    "    meter_id\n"

#     If left it here, the query will return a table with a row for each combination
#   of date range, meter and daily time period, and including the number of
#   existing meter records and meter aggregations for each row.
#     We can wrap this is another query to compare the difference between
#   records and aggregation and only return those rows where there are more
#   records than aggregations. These are the time periods, meters and
#   date ranges that we need to reaggregate for.

    sql = "SELECT\n" + \
          "    *\n" + \
          "  FROM\n" + \
          "    (\n" + \

          "  #{sql}" + \

          "    ) C\n" + \
          "    WHERE\n" + \
          "      aggregations < records\n" + \
          "    ORDER BY\n" + \
          "      start_date,\n" + \
          "      end_date,\n" + \
          "      start_time,\n" + \
          "      end_time,\n" + \
          "      meter_id\n"

    #logger.info sql

    result = ActiveRecord::Base.connection.raw_connection.exec sql
    date_ranges = Set.new []
    dtps = Set.new []
    meters = Set.new []
    result.each do |r|
      date_ranges.add( { :start_date => r["start_date"], :end_date => r["end_date"] } )
      dtps.add( { :start_time => r["start_time"].to_time, :end_time => r["end_time"].to_time } )
      meters.add( Meter.find_by_id(r["meter_id"]) )
    end


    if not ( date_ranges.empty? or daily_time_periods.empty? or meters.empty? )
      MeterAggregation.aggregate_and_store date_ranges.to_a, dtps.to_a, meters.to_a
    end

  end





# Performs an aggregation on the requested Meters, and for the time periods and
# date ranges given
#
# +Deprecated+
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +start_date+ Date
# * +end_date+ Date
# * +start_time+ Time
# * +end_time+ Time
#
# === Outputs
# Returns a floating point number for the usage

  def usage(start_date, end_date, start_time, end_time)
#   Validating the inputs

#   Check that the start_date is a date object
    return self.class.badDateError unless self.class.is_date start_date
#   Check that the start_date is a date object
    return self.class.badDateError unless self.class.is_date end_date
#   Check that the start_time is a time object
    return self.class.badTimeError unless self.class.is_time start_time
#   Check that the start_time is a time object
    return self.class.badTimeError unless self.class.is_time end_time


#   Get the usage from existing daily aggregations
    usage = aggregate_meter_usage start_date, end_date, start_time, end_time
#   IF some usage is found, return it
    return usage unless usage.nil?


#   If no aggregations for this daily time period are found, try creating some
#   We'll want to aggregate the entire date range for this meter
    aggregation_start_date = self.class.meters_first_record_date [self]

#   If there are no meter_records for this Meter, return usage 0
    return 0 unless self.class.is_date aggregation_start_date

#   There is at least one meter_record, create some aggregations
    aggregation_end_date = Date.today

#   Use the daily time period that has been requested
    daily_time_periods = [
      {
        :start_time => start_time,
        :end_time => end_time,
      }
    ]

#   Try creating the new daily aggregations
    self.class.aggregate_and_store aggregation_start_date, aggregation_end_date, daily_time_periods, [self]

#   Try getting the usage again
    usage = aggregate_meter_usage start_date, end_date, start_time, end_time
#   Return the usage, or if there isn't any, return 0
    return usage ? usage : 0


#   TODO Iteration 2 -- if there still isn't any usage, make some up

  end

#
# End Usage Interface
################################################################################















################################################################################
# Private

private


# Gets usage data. This is the method used by all usage requests
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
# * +meters+ - an array of Meter objects
# * +usage_by+ - defaults to +:time+, otherwise may be +:meter+
# * +detailed+ - boolean, defaults to false
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def self.usage date_ranges, daily_time_periods, meters, usage_by = :time, detailed = false
#   Validate the inputs
#   Check for valid date ranges
    return bad_date_range_error date_ranges unless is_valid_date_ranges date_ranges

    date_ranges = trim_date_ranges date_ranges, meters

#   Check for valid daily time periods
    return bad_daily_time_periods_error daily_time_periods unless is_valid_daily_time_periods daily_time_periods
#   Check that only Meters exist in the meters array
    return badMeterError unless is_array_of_meters meters

#   Make sure that aggregations exist for all of the daily time periods
#   requested in the given date ranges
    reaggregate date_ranges, daily_time_periods, meters

#   Get the usage...
    case usage_by
      when :time
        usages = MeterAggregation.usage_by_dtp date_ranges, daily_time_periods, meters, detailed
      when :meter
        usages = MeterAggregation.usage_by_meter date_ranges, daily_time_periods, meters, detailed
      else
        usages = MeterAggregation.usage_by_dtp date_ranges, daily_time_periods, meters, detailed
    end

#   ... and return
    return usages

  end





# Tests whether any values in the given hash are nil
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +hash+ - a hash
#
# === Outputs
# Return true or false
  def self.contains_nil_values hash
    hash.each do |key, value|
      if value.nil? then return true end
    end
    return false
  end

# ==== Deprecated
#
# Author: Reuben Braithwaite
  def self.zero_usages meters
    usages = {}
    meters.each do |m|
      usages[m.serial] = 0
    end
    return { :meters => usages }
  end


# ==== Deprecated
#
# Author: Reuben Braithwaite
  def aggregate_meter_usage start_date, end_date, start_time, end_time
    sql = "SELECT
            SUM(usage) AS usage
          FROM
            meter_aggregations
          WHERE
            meter_id = #{id}
          AND
            date >= '#{start_date}'
          AND
            date <= '#{end_date}'
          AND
            start_time = '#{start_time}'
          AND
            end_time <= '#{end_time}';"

    result = ActiveRecord::Base.connection.raw_connection.exec sql
    self.class.log_pg_result result
    return result[0]['usage'].nil? ? nil : result[0]['usage'].to_f
  end



# Finds the ealiest known date for a MeterRecord belonging to one of the
# meters in the given meter array.
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +meters+ - an array of Meter objects
#
# === Outputs
# Return Date or false
  def self.meters_first_record_date meters
#   Hash in form { meter_id => meter_serial, ...}
    whitelist = whitelist meters
    sql = "SELECT
            date
          FROM
            meter_records
          WHERE
            meter_id = ANY('{#{whitelist.keys.join(",")}}'::int[])
          ORDER BY
            date LIMIT 1"
    result = ActiveRecord::Base.connection.raw_connection.exec sql

    begin
      return result[0]['date'].to_date
    rescue
      #logger.info "No records found for Meters #{whitelist.values.join(",")}"
    end
    return false
  end



# Create a hash of meter_id => meter_serial tuples.
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +meters+ - an array of Meter objects
#
# === Outputs
# Returns a hash in the form:
# {
#   :meter_id => :meter_serial,
#   :meter_id => :meter_serial,
#   ...
#  }
  def self.whitelist meters
    whitelist = {}
    # TODO make sure each meter is a Meter
    meters.each do |meter|
      whitelist[meter.id] = meter.serial
    end
    return whitelist
  end








# ==== Deprecated
#
# Used for testing and development only -- gets dummy daiy time periods
#
# Author: Reuben Braithwaite
#
  def self.get_dtps
    return [
      {
        :label => "Peak",
        :start_time => Time.new(2000, 1, 1, 7, 0),
        :end_time => Time.new(2000, 1, 1, 19, 0),
      },
      {
        :label => "Off-Peak",
        :start_time => Time.new(2000, 1, 1, 22, 0),
        :end_time => Time.new(2000, 1, 1, 12, 0),
      },
      {
        :label => "Shoulder",
        :start_time => Time.new(2000, 1, 1, 18, 0),
        :end_time => Time.new(2000, 1, 1, 22, 0),
      },
      {
        :label => "Other time period",
        :start_time => Time.new(2000, 1, 1, 10, 30),
        :end_time => Time.new(2000, 1, 1, 5, 30),
      },
    ]
  end




end

