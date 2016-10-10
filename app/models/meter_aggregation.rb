class MeterAggregation < ActiveRecord::Base
# Include shared methods
  include Metering

  belongs_to :meter



################################################################################
# Usage methods

# Gets usage data organised by meter.
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
# * +detailed+ - boolean, defaults to false
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def self.usage_by_meter date_ranges, daily_time_periods, meters, detailed = false
    whitelist = Meter.whitelist meters
#   Get an array of top level, inclusive usage data organised by date range
    usages = inclusive_usage date_ranges, meters, detailed

    options = { :nest => true, :detailed => detailed }

    usages.each do |usage|
      usage[:source] = detailed ? "Detailed Usage by Meter" : "Usage by Meter"
      date_range = {
        :start_date => usage[:start_date],
        :end_date => usage[:end_date]
      }
#     Add an array of usage data hashes, broken down by Meter
      usage[:meters] = meter_usage date_range, daily_time_periods, whitelist, options
    end
    return usages
  end


# Gets usage data organised by daily time period.
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
# * +detailed+ - boolean, defaults to false
#
# === Outputs
# returns an array of usage hashes, as specified in Meter interface of SDD
  def self.usage_by_dtp date_ranges, daily_time_periods, meters, detailed = false
    whitelist = Meter.whitelist meters
#   Get an array of top level, inclusive usage data organised by date range
    usages = inclusive_usage date_ranges, meters, detailed

    options = { :nest => true, :detailed => detailed }

    usages.each do |usage|
      usage[:source] = detailed ? "Detailed Usage by Daily Time Period" : "Usage by Daily Time Period"
      date_range = {
        :start_date => usage[:start_date],
        :end_date => usage[:end_date]
      }
#     Add an array of usage data hashes, broken down by Daily Time Period
      usage[:daily_time_periods] = dtp_usage date_range, daily_time_periods, whitelist, options unless daily_time_periods.empty?
    end
    return usages
  end


# Gets an array of top level, inclusive usage data hashes
# As per spec Interface08, usage data in the top level
# of both returnable examples
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
# * +detailed+ - boolean, defaults to false
#
# === Outputs
# returns a hash, containing top-level usage data
  def self.inclusive_usage date_ranges, meters, detailed
    whitelist = Meter.whitelist meters
    usages = []
    date_ranges.each do |date_range|

      usage = {
        :retrieved => Time.now.to_s,
        :start_date => date_range[:start_date],
        :end_date => date_range[:end_date],
      }

      usage = (total_usage_sums date_range, whitelist).merge(usage)

      if detailed then
        usage[:daily_usage] = ( daily_full_usage_sums date_range, whitelist )
      end
      usages.push usage
    end
    return usages
  end






# Gets an array of usage data hashes by Meter
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_ranges+ - an array of hashes, each containing a Date +start_date+ and
#   Date +end_date+ as specified in Meter interface of SDD
# * +daily_time_periods+ - an array of hashes, each containing a Time
#   +start_time+, Time +end_time+ and, optionally, a String +label+, as
#   specified in Meter interface of SDD
# * +whitelist+ - hash of meter_id => meter_serial tuples
# * +options+ - hash of boolean options -- detailed, whether to nest further
#   usage data
#
# === Outputs
# returns a hash, containing meter-level usage data
  def self.meter_usage date_range, dtps, whitelist, options

    suboptions = options.clone
    suboptions[:nest] = false

    usages = total_meter_usage_sums date_range, whitelist

    usages.each do |usage|
      shortlist = { whitelist.key(usage[:serial]) => usage[:serial] }

      if options[:detailed] then
        usage[:daily_usage] = daily_full_usage_sums date_range, shortlist
      end
      if options[:nest] and (not dtps.empty?) then
        usage[:daily_time_periods] = dtp_usage date_range, dtps, shortlist, suboptions
      end
    end
    return usages
  end

# Gets an array of usage data hashes for the given Daily Time Period,
# and broken down by Meter
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_range+ - a hash containing a Date +:start_date+ and Date +:end_date+
#   as specified in Meter interface of SDD
# * +dtp+ - the daily time period, specified by +:start_time+ and +:end_time+
# * +whitelist+ - hash of meter_id => meter_serial tuples
# * +options+ - hash of boolean options -- detailed
#
# === Outputs
# returns an array, containing usage for the DTP broken down by meter
  def self.dtp_meter_usage date_range, dtp, whitelist, options

    usages = dtp_meter_usage_sums date_range, dtp, whitelist
    usages.each do |usage|
      shortlist = { whitelist.key(usage[:serial]) => usage[:serial] }
      if options[:detailed] then
        usage[:daily_usage] = daily_usage_sums date_range, dtp, shortlist
      end
    end

    return usages
  end

# Gets an array of usage data hashes for the given Daily Time Periods,
# and broken down by Meter
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_range+ - a hash containing a Date +:start_date+ and Date +:end_date+
#   as specified in Meter interface of SDD
# * +dtps+ - an array of daily time periods, eachspecified by +:start_time+
#   and +:end_time+
# * +whitelist+ - hash of meter_id => meter_serial tuples
# * +options+ - hash of boolean options -- detailed
#
# === Outputs
# returns an array, containing usage for the DTP broken down by meter
  def self.dtp_usage date_range, dtps, whitelist, options
    usages = total_dtp_usage_sums date_range, dtps, whitelist
    suboptions = options.clone
    suboptions[:nest] = false
    usages.each do |usage|
      dtp = [ { :start_time => usage[:start_time], :end_time => usage[:end_time] } ]

      if options[:detailed] then
        usage[:daily_usage] = daily_usage_sums date_range, dtp, whitelist

      end
      if options[:nest] then
        usage[:meters] = dtp_meter_usage date_range, dtp, whitelist, suboptions
      end
    end
    return usages
  end


# Gets an array of Meter's top-level total usage data hashes
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_range+ -  Date +start_date+ and Date +end_date+
# * +whitelist+ - hash of meter_id => meter_serial tuples
#
# === Outputs
# returns a array of hashes, containing meter-level total usage data
  def self.total_meter_usage_sums date_range, whitelist
    dtps = []
    dtps.push "( start_time = '#{all_day[:start_time]}' AND end_time = '#{all_day[:end_time]}' )"

    sql = "SELECT
              serial,
              SUM(usage) AS usage,
              #{confidence_query} AS confidence,
              SUM(maximum_demand) as maximum_demand,
              TRIM(unit_of_measurement) as uom
            FROM
              meter_aggregations AS MA INNER JOIN meters AS M ON M.id = MA.meter_id
            WHERE
                meter_id = ANY('{#{whitelist.keys.join(",")}}'::int[])
              AND
                ( date >= '#{date_range[:start_date]}' AND date <= '#{date_range[:end_date]}' )
              AND
                (
                  #{dtps.join(" OR ")}
                )
            GROUP BY serial, uom
            ORDER BY serial;"
    #logger.info sql
    result = ActiveRecord::Base.connection.raw_connection.exec sql
    result.map do
      |r| {
        :serial => r["serial"],
        :usage => r["usage"].to_f,
        :confidence => r["confidence"].to_f,
        :maximum_demand => r["maximum_demand"].to_f,
        :uom => r["uom"]
      }
    end
  end

# Gets the total usage each meter in the whitelist and for the date range
# specified. Returns a float.
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_range+ -  Date +start_date+ and Date +end_date+
# * +dtps+ - an array of daily time periods, eachspecified by +:start_time+
#   and +:end_time+
# * +whitelist+ - hash of meter_id => meter_serial tuples
#
# === Outputs
# returns a array of hashes, containing meter-level total usage data
  def self.dtp_meter_usage_sums date_range, dtps, whitelist
    dtp_query = []
    dtps.each do |dtp|
      dtp_query.push "( start_time = '#{dtp[:start_time]}' AND end_time = '#{dtp[:end_time]}' )"
    end

    sql = "SELECT
              serial,
              SUM(usage) AS usage,
              #{confidence_query} AS confidence,
              MAX(maximum_demand) as maximum_demand,
              TRIM(unit_of_measurement) as uom
            FROM
              meter_aggregations AS MA INNER JOIN meters AS M ON M.id = MA.meter_id
            WHERE
                meter_id = ANY('{#{whitelist.keys.join(",")}}'::int[])
              AND
                ( date >= '#{date_range[:start_date]}' AND date <= '#{date_range[:end_date]}' )
              AND
                (
                  #{dtp_query.join(" OR ")}
                )
            GROUP BY serial, uom
            ORDER BY serial;"

    result = ActiveRecord::Base.connection.raw_connection.exec sql
    result.map do
      |r| {
        :serial => r["serial"],
        :usage => r["usage"].to_f,
        :confidence => r["confidence"].to_f,
        :maximum_demand => r["maximum_demand"].to_f,
        :uom => r["uom"]
      }
    end
  end


# Gets the total usage each meter in the whitelist
# and for the date range specified.
# Gets the total usage each meter in the whitelist and for the date range
# specified. Returns a float.
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_range+ -  Date +start_date+ and Date +end_date+
# * +dtps+ - an array of daily time periods, eachspecified by +:start_time+
#   and +:end_time+
# * +whitelist+ - hash of meter_id => meter_serial tuples
#
# === Outputs
# returns a array of hashes, containing dtp-level total usage data
  def self.total_dtp_usage_sums date_range, daily_time_periods, whitelist
    specified_dtps = []
    dtps = []
    daily_time_periods. each do |dtp|
      dtps.push "( start_time = '#{dtp[:start_time]}' AND end_time = '#{dtp[:end_time]}' )"
      specified_dtps.push "
                  (
                    SELECT
                      CAST('#{dtp[:start_time]}' as time) AS start_time,
                      CAST('#{dtp[:end_time]}' as time) AS end_time,
                      '#{dtp[:label]}' AS label
                  )"
    end
      specified_dtps = specified_dtps.join("
                  UNION
")

    sql = "
          SELECT
              *
            FROM
--            DTPs
              (
                SELECT
                  start_time,
                  end_time,
                  SUM(usage) AS usage,
                  #{confidence_query} AS confidence,
                  TRIM(unit_of_measurement) as uom
                FROM
                  meter_aggregations
                WHERE
                  meter_id = ANY('{#{whitelist.keys.join(",")}}'::int[])
                AND
                  ( date >= '#{date_range[:start_date]}' AND date <= '#{date_range[:end_date]}' )
                AND
                  (
                    #{dtps.join(" OR ")}
                  )
                GROUP BY start_time, end_time, uom
              ) DTP
--            End DTPs

              NATURAL JOIN

--            Maximum Demand per DTP
              (

                SELECT
                    SUM(maximum_demand) as maximum_demand,
                    start_time,
                    end_time
                  FROM
                    (
                      SELECT
                          start_time,
                          end_time,
                          serial,
                          MAX(maximum_demand) as maximum_demand
                        FROM
                          meter_aggregations AS MA INNER JOIN meters AS M ON M.id = MA.meter_id
                        WHERE
                          meter_id = ANY('{#{whitelist.keys.join(",")}}'::int[])
                        AND
                          ( date >= '#{date_range[:start_date]}' AND date <= '#{date_range[:end_date]}' )
                        AND
                          (
                            #{dtps.join(" OR ")}
                          )
                        GROUP BY start_time, end_time, serial
                      ) MD1
                  GROUP BY start_time, end_time
              ) MD
--            End Maximum Demand per DTP

              NATURAL JOIN

--            Specified, labelled DTPs
--            This is necessary when multiple specified DTPs
--            have the same values for start and end times
              (

                #{specified_dtps}

              ) L
--            Specified, labelled DTPs

            ORDER BY start_time, end_time;"

    #logger.info sql
    result = ActiveRecord::Base.connection.raw_connection.exec sql

    return result.map do
      |r| {
        :start_time => r["start_time"],
        :end_time => r["end_time"],
        :label => r["label"],
        :usage => r["usage"].to_f,
        :confidence => r["confidence"].to_f,
        :maximum_demand => r["maximum_demand"].to_f,
        :uom => r["uom"]
      }
    end

  end

# Gets a generic sql string to retrieve a confidence value
# from selected rows
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# None
#
# === Outputs
# Returns a sql string
  def self.confidence_query
    return "
            ROUND(
              (
                SUM(
                  CASE
                    WHEN
                      source = 'r'
                    THEN
                      1.0
                    ELSE
                      0.0
                    END
                ) / COUNT(usage) ), 1
            )"
  end


# Gets the total usage for all meters in the whitelist
# and for the date range specified. Returns a float.
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_range+ -  Date +start_date+ and Date +end_date+
# * +whitelist+ - hash of meter_id => meter_serial tuples
#
# === Outputs
# returns a array of hashes, containing top-level total usage data
  def self.total_usage_sums date_range, whitelist
    dtps = []
    dtps.push "( start_time = '#{all_day[:start_time]}' AND end_time = '#{all_day[:end_time]}' )"

    sql = "SELECT
            SUM(usage) AS usage,
            #{confidence_query} AS confidence,
            SUM(maximum_demand) as maximum_demand,
            TRIM(unit_of_measurement) as uom
          FROM
            meter_aggregations
          WHERE
            meter_id = ANY('{#{whitelist.keys.join(",")}}'::int[])
          AND
            ( date >= '#{date_range[:start_date]}' AND date <= '#{date_range[:end_date]}' )
          AND
            (
              #{dtps.join(" OR ")}
            )
          GROUP BY uom;"

    result = ActiveRecord::Base.connection.raw_connection.exec sql

    if ( result.num_tuples.zero? ) then
      return {}
    end

    return {
      :usage => result[0]["usage"].to_f,
      :confidence => result[0]["confidence"].to_f,
      :maximum_demand => result[0]["maximum_demand"].to_f,
      :uom => result[0]["uom"]
    }

  end


# Returns a set of daily usage totals for the Given Date range and Meters
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_range+ -  Date +start_date+ and Date +end_date+
# * +whitelist+ - hash of meter_id => meter_serial tuples
#
# === Outputs
# returns a array of hashes, containing daily total usage data
  def self.daily_full_usage_sums date_range, whitelist
    dtps = [
      {
        :start_time => all_day[:start_time],
        :end_time => all_day[:end_time]
      }
    ]
    return daily_usage_sums date_range, dtps, whitelist
  end


# Gets the daily usages for all meters in the whitelist
# and for the date range specified.
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +date_range+ -  Date +start_date+ and Date +end_date+
# * +daily_time_periods+ - an array of daily time periods, each specified by
#   +:start_time+
#   and +:end_time+
# * +whitelist+ - hash of meter_id => meter_serial tuples
#
# === Outputs
# returns a array of hashes, containing top-level total usage data
  def self.daily_usage_sums date_range, daily_time_periods, whitelist

    dtps = []
    daily_time_periods. each do |dtp|
      dtps.push "( start_time = '#{dtp[:start_time]}' AND end_time = '#{dtp[:end_time]}' )"
    end

    sql = "SELECT
            date,
            SUM(usage) as usage,
            #{confidence_query} AS confidence,
            SUM(maximum_demand) as maximum_demand
          FROM
            meter_aggregations
          WHERE
            meter_id = ANY('{#{whitelist.keys.join(",")}}'::int[])
          AND
            ( date >= '#{date_range[:start_date]}' AND date <= '#{date_range[:end_date]}' )
          AND
            (
            #{dtps.join(" OR ")}
            )
          GROUP BY date
          ORDER BY date;"
    #logger.info sql

    result = ActiveRecord::Base.connection.raw_connection.exec sql
    return daily_usage_hash result
  end


# Formats and returns a hash of daily usages per date
#
# Author: Reuben Braithwaite
#
# ==== Inputs
# * +result+ -  pgsql result of a usage query
#
# === Outputs
# Returns a array of hashes, containing daily usage data
  def self.daily_usage_hash result
    result.map do |r| {
        :date => r["date"].to_date,
        :usage => r["usage"].to_f,
        :confidence => r["confidence"].to_f,
        :maximum_demand => r["maximum_demand"].to_f
      }
    end
  end


################################################################################
# Aggregation methods


# Aggregates usage for Daily Time Periods from existing MeterRecords.
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
  def self.aggregate_and_store date_ranges, daily_time_periods, meters

    ################################################################################
    # Inserting MeterAggregations
    #

#   Add a time period to aggregate for the whole day
    daily_time_periods.push(all_day)

#   Don't bother if there's nothing to aggregate
    if not ( date_ranges.empty? or daily_time_periods.empty? or meters.empty? )

#     This is a hash of Meters we'll be aggregating
      whitelist = Meter.whitelist meters

#     Create a WHERE clause to select by date range
#     Multiple start/end dates are possible
      date_ranges_where = date_ranges.map{
        |date_range|
        "( date >= '#{date_range[:start_date]}' AND date <= '#{date_range[:end_date]}' )"
      }.join(" OR ")


#     Create a CASE statement in order to convert the usage to k
      uom_usage_cases = nem12_uom.map{
        |uom| "              WHEN ( uom = LOWER('#{uom}') ) THEN usage * #{nem12_uom_to_kwh_multiplier uom}"
      }.join("\n")

#     Create a CASE statement in order to convert the unit of measurement to k
      uom_unit_cases = nem12_uom.map{
        |uom| "              WHEN ( uom = LOWER('#{uom}') ) THEN '#{nem12_uom_to_kuom uom}'"
      }.join("\n")

#     Initialise an array to
      aggregations = []

#     Need to create as separate subquery for each Daily Time Period
#     so loop and build for each of them
      daily_time_periods.each do |dtp|

#       Get the start and end times as a minute of the day
        start_minute = time_to_minute dtp[:start_time]
        end_minute = time_to_minute dtp[:end_time]


#       Work out a subquery to find the range within a usage array to
#       to SUM, for usage, or MAX for maximum demand for the DTP
        if start_minute == end_minute
          usage_label = "-- The whole day"
          usage_range = "UNNEST(usage) s"
        elsif start_minute < end_minute
          usage_label = "-- Daily time period not spanning midnight"
          usage_range = "UNNEST(usage[#{start_minute}/interval+1 : #{end_minute}/interval]) s"
        else
          usage_label = "-- Daily time period spanning midnight"
          usage_range = "UNNEST(usage[1 : #{end_minute}/interval] || usage[#{start_minute} / interval+1 : array_length(usage,1)]) s"
        end

#       Subquery to find a usage sum for this Daily Time Period
        usage_sum = "
                  (
                    COALESCE
                      (
                        (
                          SELECT
                              SUM(s)
                            FROM
                              #{usage_label}
                              #{usage_range}
                        ),
                        0 -- coalesce to 0 because empty arrays return null
                      )
                  ) AS usage"

#       Subquery to find a maximum demand for this Daily Time Period
        usage_max_demand = "
                  (
                    COALESCE
                      (
                        (
                          SELECT
                              60 * MAX(s) / interval
                            FROM
                              #{usage_label}
                              #{usage_range}
                        ),
                        0 -- coalesce to 0 because empty arrays return null
                      )
                  ) AS max_demand"


#       Now assemble the whole subquery for this DTP
#       This will select rows to insert as MeterAggregations
        aggregations.push("
            (
--            Aggregations for #{ dtp[:label].nil? ? 'Entire Day' : dtp[:label] }
              SELECT
                  meter_id,
                  register,
                  date,
                  TIMESTAMP '#{dtp[:start_time]}' as start_time,
                  TIMESTAMP '#{dtp[:end_time]}' as end_time,
                  --VARCHAR 'kwh' as uom,
                  LOWER(TRIM(unit_of_measurement)) AS uom,
#{usage_sum},
#{usage_max_demand}
                FROM
                  meter_records
                WHERE
                  meter_id = ANY('{#{whitelist.keys.join(",")}}'::int[])
                AND
                  ( #{date_ranges_where} )
            )
        ")
      end

#     Join each DTP's subquery with a union
      aggregations = aggregations.join("\n            UNION \n")


#     Now build the superstructure of the SQL query
      sql = "
--------------------------------------------------------------------------------
--  MeterAggregation.aggregate_and_store
--  vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

--  First thing, delete existing estimated aggregations for this date range and
--  these meters.

    DELETE FROM
        meter_aggregations
      WHERE
        meter_id = ANY('{#{whitelist.keys.join(",")}}'::int[])
      AND
        ( #{date_ranges_where} )
      AND
        source = 'a';


-- Now insert aggregations using MeterRecords

    INSERT INTO meter_aggregations
      (
        meter_id,
        register,
        date,
        start_time,
        end_time,
        unit_of_measurement,
        usage,
        maximum_demand
      )

      SELECT
          meter_id,
          register,
          date,
          start_time,
          end_time,
          --uom,
          (
            CASE
#{uom_unit_cases}
              ELSE uom
            END
          ) AS uom,
          (
            CASE
#{uom_usage_cases}
              ELSE usage
            END
          ) AS usage,
          max_demand

        FROM

          (

#{aggregations}

        ORDER BY
          meter_id,
          register,
          date

    ) R

--  No overwriting or duplicating existing records
    WHERE
      NOT EXISTS
        (
          SELECT
                1
              FROM
                meter_aggregations
              WHERE
                meter_id = R.meter_id
              AND
                start_time = CAST(R.start_time as time)
              AND
                end_time = CAST(R.end_time as time)
              AND
                register = R.register
              AND
                date = R.date
        );

--  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--  MeterAggregation.aggregate_and_store
--------------------------------------------------------------------------------
"

      result = ActiveRecord::Base.connection.raw_connection.exec sql

    # Done inserting MeterAggregations
     #logger.info sql
    # log_pg_result result
    ################################################################################

#     Make up some data for any gaps
      aggregate_missing_data date_ranges, daily_time_periods, meters

#     Call to MeterPredictor here
      date_ranges.each do |dr|
        Meter.predictor.calculate dr[:start_date], dr[:end_date], daily_time_periods, meters
      end

  else
      #logger.info "\\\\\\\\ Didn't aggregate_and_store anything"
    end


  end













# Finds gaps in aggregated data and fills them with estimations
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
  def self.aggregate_missing_data date_ranges, daily_time_periods, meters

#   This query gets mighty big.
#   So I've split the date ranges into yearly chunks
#   and run them 1 at a time. i.e., 1 x 5 year date range
#   will be converted to 5 x 1 date ranges
    new_date_ranges = []

    date_ranges.each do |dr|
      start_date = dr[:start_date]
      end_date = dr[:end_date]
      while ( end_date - start_date > 365 ) do
        new_date_ranges.push ({
          :start_date => start_date,
          :end_date => start_date + 1.year - 1.day > end_date ? end_date : start_date + 1.year - 1.day
        })
        start_date = start_date + 1.year
      end
      new_date_ranges.push ({
        :start_date => start_date,
        :end_date => start_date + 1.year - 1.day > end_date ? end_date : start_date + 1.year - 1.day
      })
    end


    date_ranges = new_date_ranges
    new_date_ranges.each do |dr|

      date_ranges = [dr]



    whitelist = Meter.whitelist meters


#   Create a subquery to select each dtp
#   These will be cross joined with dates / meters / registers
#   to provide a set of missing aggregations that need to be accounted for
    dtps = []
    daily_time_periods.each do |dtp|
      dtps.push "
                                  (
--                                  #{ dtp[:label].nil? ? 'Entire Day' : dtp[:label] }
                                    SELECT
                                        TIMESTAMP '#{dtp[:start_time]}' as start_time,
                                        TIMESTAMP '#{dtp[:end_time]}' as end_time
                                  )
                            "
    end
#   ... and union those DTPs
    dtps = dtps.join("
                                  UNION
")

#   Create a subquery to generate a comprehensive set of dates in
#   the date ranges required
    all_dates = []
#   and a string to use as a WHERE clause to select existing records
    records_dates = []
#   Add the dates for each Date Range
    date_ranges.each do |date_range|
      all_dates.push "
                                          SELECT
                                              date::date
                                            FROM
                                              generate_series(
                                                '#{date_range[:start_date]}',
                                                '#{date_range[:end_date]}',
                                                '1 day'::INTERVAL
                                              ) date
"

      records_dates = date_ranges.map { |date_range| "
                                                    (
                                                        date >= '#{date_range[:start_date]}'
                                                      AND
                                                        date <= '#{date_range[:end_date]}'
                                                    )
"}

    end

    all_dates = all_dates.join("              UNION")
    records_dates = records_dates.join("
                                                  OR")



    sql = "

--------------------------------------------------------------------------------
--  MeterAggregation.aggregate_missing_data
--  vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

          INSERT INTO

            meter_aggregations

              (
                meter_id,
                register,
                date,
                start_time,
                end_time,
                source,
                unit_of_measurement,
                usage,
                maximum_demand
              )

              SELECT
                  meter_id,
                  register,
                  date,
                  start_time,
                  end_time,
                  source,
                  unit_of_measurement,
                  usage,
                  (
                    CASE
                      WHEN
                        start_minute = end_minute
                      THEN
                        -- The whole day
                        60 * usage / 1440
                      WHEN
                        start_minute < end_minute
                      THEN
                        -- Daily time period not spanning midnight
                        60 * usage / ( end_minute - start_minute )
                      ELSE
                        -- Daily time period spanning midnight
                        60 * usage / ( 1440 - start_minute + end_minute )
                      END
                  ) as maximum_demand
                FROM

                  (
                    SELECT
--                      Values to insert into meter_aggregations
                        meter_id,
                        register,
                        date,
                        start_time,
                        end_time,
                        'a' AS source,
                        COALESCE (
--                        Use the same uom as previous data if there is some
                          (
                            SELECT
                                unit_of_measurement
                            FROM
                              meter_records
                            WHERE
                              meter_id = DMRT.meter_id
                            AND
                              register = DMRT.register
                            AND
                              date = DMRT.source_date
                            LIMIT 1
                          ),
--                        Default to 'kwh' if there's no previous data
                          'kwh'
                        ) AS unit_of_measurement,

                        COALESCE (
--                        When there's a valid source date to get some data from
                          (
                            SELECT
                                (
                                  CASE
                                    WHEN
                                      DMRT.start_minute = DMRT.end_minute
                                    THEN
                                      ( SELECT SUM(s) FROM UNNEST(usage) s )
                                    WHEN
                                      DMRT.start_minute < DMRT.end_minute
                                    THEN
                                      ( SELECT SUM(s) FROM UNNEST(usage[DMRT.start_minute / interval+1 : DMRT.end_minute / interval]) s )
                                    ELSE
                                      ( SELECT SUM(s) FROM UNNEST(usage[1 : DMRT.start_minute/interval] || usage[DMRT.end_minute / interval + 1 : array_length(usage,1)]) s )
                                  END
                                )
                              FROM
                                meter_records
                              WHERE
                                meter_id = DMRT.meter_id
                              AND
                                register = DMRT.register
                              AND
                                date = DMRT.source_date
                              LIMIT 1
                          ),
--                        When there's NOT a valid source date to get some data from
                          (
                            CASE
                              WHEN
                                DMRT.start_minute = DMRT.end_minute
                              THEN
                                -- The whole day
                                ( 160.0 * 1000.0 ) / 365.0
                              WHEN
                                DMRT.start_minute < DMRT.end_minute
                              THEN
                                -- Daily time period not spanning midnight
                                ( ( 160.0 * 1000.0 ) / 365.0 ) * ( ( DMRT.end_minute - DMRT.start_minute ) / 1440 )
                              ELSE
                                -- Daily time period spanning midnight
                                ( ( 160.0 * 1000.0 ) / 365.0 ) * ( ( 1440 - DMRT.start_minute + DMRT.end_minute ) / 1440 )
                              END
                            )
                        ) AS usage,
--                      Hang on to start/end as a number of minutes so we can
--                      use them to calculate max demand
                        start_minute,
                        end_minute
                      FROM

                        (
                          SELECT
                              meter_id,
                              register,
                              date,
                              source_date,
                              start_time,
                              end_time,
                              ( EXTRACT(MINUTE FROM start_time) + EXTRACT(HOUR FROM start_time) * 60 ) AS start_minute,
                              ( EXTRACT(MINUTE FROM end_time) + EXTRACT(HOUR FROM end_time) * 60 ) AS end_minute
                            FROM
                              (
                                (
#{dtps}
                                )
                              ) DTP

                              CROSS JOIN

                              (
                                SELECT
                                    meter_id,
                                    register,
                                    date,
--                                  Coalesce target dates here
--                                  Find the date to aggregate, if one exists
                                    COALESCE (
                                      (
                                        SELECT
                                            date
                                          FROM
                                            meter_records
                                          WHERE
                                            meter_id = CJ.meter_id
                                          AND
                                            register = CJ.register
                                          AND
                                            date = CJ.date - '1 year'::INTERVAL
                                      ),
                                      (
--    TODO -- this needs to loop, trying every previous billing period
--    to find a record, until 11 month prior to requested date.

                                        SELECT
                                            date
                                          FROM
                                            meter_records
                                          WHERE
                                            meter_id = CJ.meter_id
                                          AND
                                            register = CJ.register
                                          AND
                                            date = CJ.date - '1 month'::INTERVAL
                                      ),
                                      NULL
                                    ) AS source_date

                                  FROM

--                                  Cross Join, CJ, to get all required permutations of
--                                  date, meter and register
                                    (
--                                    Select each date we expect a record for
                                      SELECT
                                          date,
                                          meter_id,
                                          register
                                        FROM
                                          (
#{all_dates}
                                          ) D

                                          CROSS JOIN

                                          (
--                                          Unique meters / registers
                                            SELECT DISTINCT
                                                meter_id,
                                                register
                                              FROM
                                                meter_records
                                              WHERE
                                                meter_id = ANY('{#{whitelist.keys.join(",")}}'::int[])
                                          ) MR

                                    ) CJ

--                                  End cross joining meters / registers / dates but
--                                  only pick those permutations that we don't have
--                                  existing records for

                                    WHERE  NOT EXISTS

                                      (
                                        SELECT
                                            1
                                          FROM
                                            (
--                                            Records that DO exist in these date ranges
                                              SELECT
                                                  meter_id,
                                                  register,
                                                  date
                                                FROM
                                                  meter_records
                                                WHERE
                                                  (
#{records_dates}
                                                  )
                                            ) R
                                          WHERE
                                            CJ.date = R.date
                                          AND
                                            CJ.meter_id = R.meter_id
                                          AND
                                            CJ.register = R.register
                                      )
                                    ORDER BY
                                      date,
                                      meter_id,
                                      register
                                  ) DMR
                          ) DMRT

                  ) MA

--  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--  MeterAggregation.aggregate_missing_data
--------------------------------------------------------------------------------

"
      #logger.info sql
      result = ActiveRecord::Base.connection.raw_connection.exec sql

    end

  end # End date range loop here

end
