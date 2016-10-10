class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  @@metrics = {}
  @@num_benchmark_iterations = 100

  def experiments
    return [ "Generate NEM12",
      "Import NEM12",
      "Import NEM12 (Readline 1 Query)",
      "Import NEM12 (Readline 53 Queries)",
      "Import NEM12 Rails",
      "Import NEM12 (Readline 53 Queries) and Aggregate and Store Daily Usage",
      "Import NEM12 and Aggregate and Store Daily Usage Rails",
      "Rails Insert",
      "SQL Insert",
      "Aggregate Daily Usage",
      "Aggregate and Store Daily Usage",
      "Aggregate and Store Daily Usage Rails",
      "Import NEM12 and Aggregate and Store Daily Usage",
      "Aggregate Weekly Usage",
      "Aggregate Monthly Usage",
      "Aggregate Quarterly Usage",
      "Aggregate Yearly Usage",
      "Aggregate Weekly Usage From Daily Aggregation",
      "Aggregate Weekly Usage From Daily Aggregation Rails",
      "Aggregate Monthly Usage From Daily Aggregation",
      "Aggregate Monthly Usage From Daily Aggregation Rails",
      "Aggregate Quarterly Usage From Daily Aggregation",
      "Aggregate Quarterly Usage From Daily Aggregation Rails",
      "Aggregate Yearly Usage From Daily Aggregation",
      "Aggregate Yearly Usage From Daily Aggregation Rails",
      "Aggregate Monthly Usage From Daily Aggregation (1 Query)"
    ]
  end


# Imports NEM12
  def index
#   Remove the ActiveRecord logger -- it slows stuff down
    active_record_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil

#   Set up a hash containing metrics for each experiment
    initialise_metrics params
#   Run experiments as many times as is determined by @@num_benchmark_iterations
    (1..@@num_benchmark_iterations).each do |i|
#     Iterate through known experiments
      experiments.each do |experiment|
#       Was the experiment requested by the view's form?
        if params[experiment]
#         Run the experiment
          run_experiment experiment, i
        end
      end
    end

#   Write results to log at /log/development.log
    log_metrics
#   This is needed by the view's form
    @experiments = experiments

#   Reinstate the ActiveRecord Logger
    ActiveRecord::Base.logger = active_record_logger
  end


# Sets up a hash containing metrics for each of the experiments being run
# Records a sum of total time taken for each run of the experiment
# The fastest time, the slowest time
  def initialise_metrics params
#   Create a hash to store everything in
    @@metrics = {}
#   Iterate through known experiments
    experiments.each do |experiment|
#     Was the experiment requested by the view's form?
      if params[experiment]
#       Create a hash for each ixperiment that has been requested
        experiment = experiment.parameterize.underscore.to_sym
        @@metrics[experiment] = {
          :total => 0,
          :fastest => nil,
          :slowest => nil,
          :times => [] ,
          :query_total => 0,
          :query_fastest => nil,
          :query_slowest => nil,
          :query_times => [] ,
        }
      end
    end
  end

# Adds a metric for the experiment that's just run
  def update_metric experiment, time_taken
#   Was this the fastest run?
    if @@metrics[experiment][:fastest].nil? or time_taken < @@metrics[experiment][:fastest]
      fastest = time_taken
    else
      fastest = @@metrics[experiment][:fastest]
    end
#   Or the slowest run?
    if @@metrics[experiment][:slowest].nil? or time_taken > @@metrics[experiment][:slowest]
      slowest = time_taken
    else
      slowest = @@metrics[experiment][:slowest]
    end
#   Add to the total
    total = @@metrics[experiment][:total] + time_taken

#   Add this time to stored times
    @@metrics[experiment][:times].push(time_taken)

    @@metrics[experiment][:fastest] = fastest
    @@metrics[experiment][:slowest] = slowest
    @@metrics[experiment][:total] = total
    @@metrics[experiment][:times] = @@metrics[experiment][:times]

  end


# ActiveRecord interface times -- not implemented right now
  def update_active_record_metric experiment, event
#   Was this the fastest run?
    if @@metrics[experiment][:query_fastest].nil? or event.duration < @@metrics[experiment][:query_fastest]
      fastest = event.duration
    else
      fastest = @@metrics[experiment][:query_fastest]
    end
#   Or the slowest run?
    if @@metrics[experiment][:query_slowest].nil? or event.duration > @@metrics[experiment][:query_slowest]
      slowest = event.duration
    else
      slowest = @@metrics[experiment][:query_slowest]
    end
#   Add to the total
    total = @@metrics[experiment][:query_total] + event.duration

#   Add this time to stored times
    @@metrics[experiment][:query_times].push(event.duration)

    @@metrics[experiment][:query_fastest] = fastest
    @@metrics[experiment][:query_slowest] = slowest
    @@metrics[experiment][:query_total] = total
    @@metrics[experiment][:query_times] = @@metrics[experiment][:times]
  end



# Write all metrics to log
  def log_metrics
    logger.info ""
    logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    logger.info " #{Time.now().strftime('%H:%M, %e %B %Y')}"  # day.ordinalize
    logger.info " #{@@num_benchmark_iterations} Iterations"
    logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    experiments.each do |experiment|
#     Was the experiment requested by the view's form?
      sym = experiment.parameterize.underscore.to_sym
      if @@metrics.has_key?(sym)
        metric = @@metrics[sym]
        logger.info ""
        logger.info experiment
        logger.info "Mean: #{sprintf("%0.02f", metric[:total] / @@num_benchmark_iterations * 1000)}ms"
        logger.info "Fastest: #{sprintf("%0.02f", metric[:fastest]*1000)}ms"
        logger.info "Slowest: #{sprintf("%0.02f", metric[:slowest]*1000)}ms"

#       This will output all the times stored for experiments run
        metric[:times].each do |time|
          logger.info "#{sprintf("%0.02f", time*1000)}ms"
        end

#        This is
#        logger.info "Query Mean: #{sprintf("%0.02f", metric[:query_total] / @@num_benchmark_iterations * 1000)}ms"
#        logger.info "Query Fastest: #{sprintf("%0.02f", metric[:query_fastest]*1000)}ms"
#        logger.info "Query Slowest: #{sprintf("%0.02f", metric[:query_slowest]*1000)}ms"
#        logger.info ""
      end
    end

    logger.info ""
    logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    logger.info ""
  end





# Run an experiment
  def run_experiment experiment, i
#   Run any initialization that needs to happen for the experiment
#   i.e., truncate tables etc
    #logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n Cleaning up for #{experiment}"
    initialiser = "Initialise #{experiment}".parameterize.underscore.to_sym
    send(initialiser) if self.respond_to? initialiser
    #logger.info "\n Done cleaning up for #{experiment}\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"

#   Symbolize to get the method name for the experiment
    experiment = experiment.parameterize.underscore.to_sym

#   Clear the query cache -- otherwise it'll be an inaccurate measurement
    Meter.connection.clear_query_cache
    MeterRecord.connection.clear_query_cache
    MeterAggregation.connection.clear_query_cache

#    Using this will break the regular Active Record interface
#    and result in a PG::InvalidSqlStatementName: ERROR: prepared statement "a1" does not exist :
#    Restart the server will fix the problem

#    sql = "DISCARD ALL"
#    results = ActiveRecord::Base.connection.raw_connection.exec sql

#    ActiveRecord::Base.connection.clear_cache!

#   Capture ActiveRecord Query times for the experiment

#    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
#      event = ActiveSupport::Notifications::Event.new(*args)
#      update_active_record_metric(experiment, event)
#    end

#   Note in the log that the experiment is running
    logger.info "\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\nRunning Experiment: #{experiment}"
    logger.info "Iteration #{i}\n\n"

#   Initialise a timer
    time_taken = 0
#   Wrap queries inside a single commit

#   Start a timer to get a metric on this experiment
    timer_start = Time.now()
    ActiveRecord::Base.transaction do

#     Run the experiment
      send(experiment)

#     This is the time that the experiment took to happen
    end
    time_taken = Time.now() - timer_start

#   Add timing to metrics
#   TODO record Active Record execution time
    update_metric experiment, time_taken

#    ActiveSupport::Notifications.unsubscribe('sql.active_record')
#    ActiveSupport::Notifications.unsubscribe(subscriber)
    logger.info "\n\nExperiment Done: #{time_taken*1000}ms\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n"
  end






##
#  Initialisers
##

# Required setup for import_nem12
  def initialise_import_nem12
    truncate_meters
    truncate_meter_records
    truncate_meter_aggregations
  end

# Required setup for import_nem12
  def initialise_import_nem12_readline_1_query
    truncate_meters
    truncate_meter_records
    truncate_meter_aggregations
  end

# Required setup for import_nem12
  def initialise_import_nem12_readline_53_queries_and_aggregate_and_store_daily_usage
    truncate_meters
    truncate_meter_records
    truncate_meter_aggregations
  end

# Required setup for import_nem12
  def initialise_import_nem12_and_aggregate_and_store_daily_usage_rails
    truncate_meters
    truncate_meter_records
    truncate_meter_aggregations
  end

# Required setup for import_nem12
  def initialise_import_nem12_readline_53_queries
    truncate_meters
    truncate_meter_records
    truncate_meter_aggregations
  end


# Required setup for import_nem12
  def initialise_import_nem12_rails
    truncate_meters
    truncate_meter_records
    truncate_meter_aggregations
  end


# Required setup for import_nem12_and_aggregate_and_store_daily_usage
  def initialise_import_nem12_and_aggregate_and_store_daily_usage
    truncate_meters
    truncate_meter_records
    truncate_meter_aggregations
  end

# Required setup for aggregate_daily_usage
  def initialise_aggregate_and_store_daily_usage
    truncate_meter_aggregations
  end

# Required setup for aggregate_daily_usage
  def initialise_aggregate_and_store_daily_usage_rails
    truncate_meter_aggregations
  end


# Required setup for aggregate_weekly_usage
  def initialise_rails_insert
    truncate_meter_aggregations
    record = {
      :aggregation => 1.1,
      :meter_serial => '2020',
      :start_time => 0,
      :end_time => 48,
      :date => Time.now()
    }

    @@rails_records = []
    (1..7420).each do |i|
      @@rails_records.push record
    end
  end

# Required setup for aggregate_weekly_usage
  def initialise_sql_insert
    truncate_meter_aggregations
    record = "( '2020', '#{Time.now()}', 0, 48, 1.1 )"
    @@sql_records = []
    (1..7420).each do |i|
      @@sql_records.push record
    end
  end


# Truncators

# Truncate meters
  def truncate_meters
    #logger.info "Truncating meters"
    ActiveRecord::Base.connection.execute("TRUNCATE meters")
  end

# Truncate meter_records
  def truncate_meter_records
    #logger.info "Truncating meter_records"
    ActiveRecord::Base.connection.execute("TRUNCATE meter_records")
  end

# Truncate meter_aggregations
  def truncate_meter_aggregations
    #logger.info "Truncating meter_aggregations"
    ActiveRecord::Base.connection.execute("TRUNCATE meter_aggregations")
  end

##
#  End Initialisers
##





##
#  Experiments
##

# Quick example of how slow standard Rails inserts are
# Compare it to the method immediately below -- they use exactly the same records
  def rails_insert
    #logger.info @@rails_records
    MeterAggregation.create(@@rails_records)
  end

# Quick example of how slow standard Rails inserts are compared to SQL
# Compare it to the method immediately above -- they use exactly the same records
  def sql_insert
    sql = "INSERT INTO meter_aggregations (meter_serial, date, start_time, end_time, aggregation) \
            VALUES #{@@sql_records.join(", ")}"
    results = ActiveRecord::Base.connection.raw_connection.exec sql
  end




# Import from .csv files
  def import_nem12_readline_1_query
    #sql = "create table "
    meters = []
    meter_records = []


    Dir.glob("#{generated_data_directory}/*.csv") do |filename|
      nmi = ""
      serial = ""
      interval = 1

      file = File.open(filename, 'r')
      while !file.eof?
        # Add row to copy data
        record = file.readline.split(",")
        identifier = record[0]
        case identifier
          when '100'
          when '200'
            nmi = record[1]
            serial = record[6]
            interval = record[8].to_i
            meters.push("('#{nmi}','#{serial}')") unless meters.include? "('#{nmi}','#{serial}')"
          when '300'
#            values = record[2...2+minutes_in_day/interval]
            values = record[2...2+minutes_in_day/interval].map { |s| s.to_f }
            #values = [1.1, 2.2, 3.3]
            date = record[1].to_date
            meter_records.push( "( '#{serial}', '#{date}', ARRAY#{values}, #{interval} )" )
        end
      end
    end

      if ( meter_records.length > 0 )
        sql = "INSERT INTO meter_records (meter_serial, date, values, meter_interval) VALUES #{meter_records.join(", ")}"
        results = ActiveRecord::Base.connection.raw_connection.exec sql
      end

      if ( meters.length > 0 )
        sql = "INSERT INTO meters (nmi, serial) VALUES #{meters.join(", ")}"
        results = ActiveRecord::Base.connection.raw_connection.exec sql
      end


  end


# Import from .csv files
  def import_nem12_readline_53_queries
    meters = []
    query_num = 0

    Dir.glob("#{generated_data_directory}/*.csv") do |filename|
      nmi = ""
      serial = ""
      interval = 1
      meter_records = []

      file = File.open(filename, 'r')
      while !file.eof?
        # Add row to copy data
        record = file.readline.split(",")
        identifier = record[0]
        case identifier
          when '100'
          when '200'
            nmi = record[1]
            serial = record[6]
            interval = record[8].to_i
            meters.push("('#{nmi}','#{serial}')") unless meters.include? "('#{nmi}','#{serial}')"
          when '300'
            values = record[2...2+minutes_in_day/interval]
            values = record[2...2+minutes_in_day/interval].map { |s| s.to_f }
            date = record[1].to_date
            meter_records.push( "( '#{serial}', '#{date}', ARRAY#{values}, #{interval} )" )
        end


      end

      if ( meter_records.length > 0 )
        sql = "INSERT INTO meter_records (meter_serial, date, values, meter_interval) VALUES #{meter_records.join(", ")}"
        results = ActiveRecord::Base.connection.raw_connection.exec sql
      end

    end

    if ( meters.length > 0 )
      sql = "INSERT INTO meters (nmi, serial) VALUES #{meters.join(", ")}"
      results = ActiveRecord::Base.connection.raw_connection.exec sql
    end

  end


# Import from .csv files
  def import_nem12_rails
    meters = []
    query_num = 0

    Dir.glob("#{generated_data_directory}/*.csv") do |filename|
      nmi = ""
      serial = ""
      interval = 1
      meter_records = []

      file = File.open(filename, 'r')
      while !file.eof?
        # Add row to copy data
        record = file.readline.split(",")
        identifier = record[0]
        case identifier
          when '100'
          when '200'
            nmi = record[1]
            serial = record[6]
            interval = record[8].to_i
            meters.push("('#{nmi}','#{serial}')") unless meters.include? "('#{nmi}','#{serial}')"
          when '300'
            values = record[2...2+minutes_in_day/interval]
            values = record[2...2+minutes_in_day/interval].map { |s| s.to_f }
            date = record[1].to_date
            record = {
              :meter_serial => serial,
              :date => date,
              :values => values,
              :meter_interval => interval
            }
            meter_records.push( record )
        end


      end

      if ( meter_records.length > 0 )
        MeterRecord.create(meter_records)
      end

    end

    if ( meters.length > 0 )
      sql = "INSERT INTO meters (nmi, serial) VALUES #{meters.join(", ")}"
      results = ActiveRecord::Base.connection.raw_connection.exec sql
    end

  end


  def import_nem12_readline_53_queries_and_aggregate_and_store_daily_usage
    meters = []
    query_num = 0

    Dir.glob("#{generated_data_directory}/*.csv") do |filename|
      nmi = ""
      serial = ""
      interval = 1
      meter_records = []
      meter_aggregations = []

      file = File.open(filename, 'r')
      while !file.eof?
        # Add row to copy data
        record = file.readline.split(",")
        identifier = record[0]
        case identifier
          when '100'
          when '200'
            nmi = record[1]
            serial = record[6]
            interval = record[8].to_i
            meters.push("('#{nmi}','#{serial}')") unless meters.include? "('#{nmi}','#{serial}')"
          when '300'
            values = record[2...2+minutes_in_day/interval]
            values = record[2...2+minutes_in_day/interval].map { |s| s.to_f }
            date = record[1].to_date
            meter_records.push( "( '#{serial}', '#{date}', ARRAY#{values}, #{interval} )" )
#           Calculate aggregations
            billing_time_periods = Billing.time_periods
        #   Run an aggregation, and store, for each of them
            billing_time_periods.each do |time_period|
              aggregation = values[(Billing.time_period_length * time_period[:start]/interval+1)..(Billing.time_period_length * time_period[:end]/interval)].inject(:+)
              #logger.info "Aggregation: #{aggregation}"
              meter_aggregations.push( "( '#{serial}', '#{date}', #{time_period[:start]}, #{time_period[:end]}, #{aggregation} )" )
            end
        end


      end

      if ( meter_records.length > 0 )
        sql = "INSERT INTO meter_records (meter_serial, date, values, meter_interval) VALUES #{meter_records.join(", ")}"
        results = ActiveRecord::Base.connection.raw_connection.exec sql
      end


      if ( meter_aggregations.length > 0 )
  #     Insert Meter Aggregations
        sql = "INSERT INTO meter_aggregations (meter_serial, date, start_time, end_time, aggregation) VALUES #{meter_aggregations.join(", ")}"
        results = ActiveRecord::Base.connection.raw_connection.exec sql
      end

    end

    if ( meters.length > 0 )
      sql = "INSERT INTO meters (nmi, serial) VALUES #{meters.join(", ")}"
      results = ActiveRecord::Base.connection.raw_connection.exec sql
    end



  end

  def import_nem12_and_aggregate_and_store_daily_usage_rails
    meters = []
    query_num = 0

    Dir.glob("#{generated_data_directory}/*.csv") do |filename|
      nmi = ""
      serial = ""
      interval = 1
      meter_records = []
      meter_aggregations = []

      file = File.open(filename, 'r')
      while !file.eof?
        # Add row to copy data
        record = file.readline.split(",")
        identifier = record[0]
        case identifier
          when '100'
          when '200'
            nmi = record[1]
            serial = record[6]
            interval = record[8].to_i
            meters.push("('#{nmi}','#{serial}')") unless meters.include? "('#{nmi}','#{serial}')"
          when '300'
            values = record[2...2+minutes_in_day/interval]
            values = record[2...2+minutes_in_day/interval].map { |s| s.to_f }
            date = record[1].to_date
            record = {
              :meter_serial => serial,
              :date => date,
              :values => values,
              :meter_interval => interval
            }
            meter_records.push( record )
#           Calculate aggregations
            billing_time_periods = Billing.time_periods
        #   Run an aggregation, and store, for each of them
            billing_time_periods.each do |time_period|
              aggregation = values[(Billing.time_period_length * time_period[:start]/interval+1)..(Billing.time_period_length * time_period[:end]/interval)].inject(:+)
              #logger.info "Aggregation: #{aggregation}"
              #meter_aggregations.push( "( '#{serial}', '#{date}', #{time_period[:start]}, #{time_period[:end]}, #{aggregation} )" )
              aggregation_record = {
                :meter_serial => serial,
                :date => date,
                :start_time => time_period[:start],
                :end_time => time_period[:end],
                :aggregation => aggregation,
              }
              meter_aggregations.push( aggregation_record )

            end
        end


      end

      if ( meter_records.length > 0 )
        MeterRecord.create(meter_records)
      end


      if ( meter_aggregations.length > 0 )
  #     Insert Meter Aggregations
        MeterAggregation.create(meter_aggregations)

        #sql = "INSERT INTO meter_aggregations (meter_serial, date, start_time, end_time, aggregation) VALUES #{meter_aggregations.join(", ")}"
        #results = ActiveRecord::Base.connection.raw_connection.exec sql
      end

    end

    if ( meters.length > 0 )
      sql = "INSERT INTO meters (nmi, serial) VALUES #{meters.join(", ")}"
      results = ActiveRecord::Base.connection.raw_connection.exec sql
    end



  end










# Import from .csv files
  def import_nem12
    require 'csv'
    meters = []
    nmi = ""
    serial = ""
    interval = 1
    meter_records = []

    Dir.glob("#{generated_data_directory}/*.csv") do |filename|

      #csv = CSV.read(filename, col_sep: ",", encoding: "ISO8859-1", headers: false)
      #csv.each do |record|

      #csv_file = File.open(filename,"r:ISO-8859-1")
      #csv = CSV.parse(csv_file, :headers => false)
      #csv.each do |record|

      CSV.foreach(filename, {:encoding => 'ISO8859-1', :col_sep => ',', :row_sep => :auto, :headers => false}) do |record|
        case record[0]
          when '200'
            nmi = record[1]
            serial = record[6]
            interval = record[8].to_i
            meters.push("('#{nmi}','#{serial}')") unless meters.include? "('#{nmi}','#{serial}')"
          when '300'
            values = record[2...2+minutes_in_day/interval].map { |s| s.to_f }
            date = record[1].to_date
            meter_records.push( "( '#{serial}', '#{date}', ARRAY#{values}, #{interval} )" )
        end
      end
    end

    if ( meter_records.length > 0 )
      sql = "INSERT INTO meters (nmi, serial) VALUES #{meters.join(", ")}"
#      results = ActiveRecord::Base.transaction { ActiveRecord::Base.connection.raw_connection.exec sql }
      results = ActiveRecord::Base.connection.raw_connection.exec sql
      sql = "INSERT INTO meter_records (meter_serial, date, values, meter_interval) VALUES #{meter_records.join(", ")}"
#      results = ActiveRecord::Base.transaction { ActiveRecord::Base.connection.raw_connection.exec sql }
      results = ActiveRecord::Base.connection.raw_connection.exec sql
    end
  end












  def import_nem12_and_aggregate_and_store_daily_usage
    require 'csv'
    nmi = ""
    serial = ""
    interval = 1
    meters = []
    meter_records = []
    meter_aggregations = []

    Dir.glob("#{generated_data_directory}/*.csv") do |filename|

      CSV.foreach(filename, {:encoding => 'ISO8859-1', :col_sep => ',', :row_sep => :auto, :headers => false}) do |record|
        case record[0]
          when '200'
            nmi = record[1]
            serial = record[6]
            interval = record[8].to_i
            meters.push("('#{nmi}','#{serial}')") unless meters.include? "('#{nmi}','#{serial}')"
          when '300'
            values = record[2...2+minutes_in_day/interval].map { |s| s.to_f }
            date = record[1].to_date
            meter_records.push( "( '#{serial}', '#{date}', ARRAY#{values}, #{interval} )" )

#           Calculate aggregations
            billing_time_periods = Billing.time_periods
        #   Run an aggregation, and store, for each of them
            billing_time_periods.each do |time_period|
              aggregation = values[(Billing.time_period_length * time_period[:start]/interval+1)..(Billing.time_period_length * time_period[:end]/interval)].inject(:+)
              #logger.info "Aggregation: #{aggregation}"
              meter_aggregations.push( "( '#{serial}', '#{date}', #{time_period[:start]}, #{time_period[:end]}, #{aggregation} )" )
            end


        end
      end
    end

    if ( meter_records.length > 0 )
#     Insert Meters
      sql = "INSERT INTO meters (nmi, serial) VALUES #{meters.join(", ")}"
#      results = ActiveRecord::Base.transaction { ActiveRecord::Base.connection.raw_connection.exec sql }
      results = ActiveRecord::Base.connection.raw_connection.exec sql
#     Insert Meter Records
      sql = "INSERT INTO meter_records (meter_serial, date, values, meter_interval) VALUES #{meter_records.join(", ")}"
#      results = ActiveRecord::Base.transaction { ActiveRecord::Base.connection.raw_connection.exec sql }
      results = ActiveRecord::Base.connection.raw_connection.exec sql
#     Insert Meter Aggregations
      sql = "INSERT INTO meter_aggregations (meter_serial, date, start_time, end_time, aggregation) VALUES #{meter_aggregations.join(", ")}"
      results = ActiveRecord::Base.connection.raw_connection.exec sql
    end
  end


# Aggregating Daily Usage from meter_records
  def aggregate_daily_usage
#   Get the time periods to aggregate from Billing
    billing_time_periods = Billing.time_periods
#   Run an aggregation, and store, for each of them
    billing_time_periods.each do |time_period|
      start_numerator = Billing.time_period_length * time_period[:start]
      end_numerator = Billing.time_period_length * time_period[:end]
      sql = "SELECT meter_serial, date, #{time_period[:start]} as start_time,
              #{time_period[:end]} as end_time, (SELECT SUM(s) FROM UNNEST( \
                values[#{start_numerator}/meter_interval+1:#{end_numerator}/meter_interval]) s ) \
                  AS aggregation FROM meter_records ORDER BY meter_serial, date;"

      results = ActiveRecord::Base.connection.raw_connection.exec sql
#      results = ActiveRecord::Base.transaction { ActiveRecord::Base.connection.raw_connection.exec sql }
    end
  end


# Aggregating Daily Usage from meter_records
  def aggregate_and_store_daily_usage
#   Get the time periods to aggregate from Billing
    billing_time_periods = Billing.time_periods
#   Run an aggregation, and store, for each of them
    billing_time_periods.each do |time_period|
      start_numerator = Billing.time_period_length * time_period[:start]
      end_numerator = Billing.time_period_length * time_period[:end]
      sql = "INSERT INTO meter_aggregations (meter_serial, date, start_time, end_time, aggregation) \
              SELECT meter_serial, date, #{time_period[:start]} as start_time, #{time_period[:end]} as end_time, \
              (SELECT SUM(s) FROM UNNEST( \
                values[#{start_numerator}/meter_interval+1:#{end_numerator}/meter_interval]) s ) \
                  AS aggregation FROM meter_records ORDER BY meter_serial, date;"
      results = ActiveRecord::Base.connection.raw_connection.exec sql
    end
  end

# Aggregating Daily Usage from meter_records
# TODO — is there any point in implementing this the Rails way? It'll be super slow.
  def aggregate_and_store_daily_usage_rails
#   Get the time periods to aggregate from Billing
    billing_time_periods = Billing.time_periods
#   Run an aggregation, and store, for each of them
    billing_time_periods.each do |time_period|
      start_numerator = Billing.time_period_length * time_period[:start]
      end_numerator = Billing.time_period_length * time_period[:end]
      sql = "INSERT INTO meter_aggregations (meter_serial, date, start_time, end_time, aggregation) \
              SELECT meter_serial, date, #{time_period[:start]} as start_time, #{time_period[:end]} as end_time, \
              (SELECT SUM(s) FROM UNNEST( \
                values[#{start_numerator}/meter_interval+1:#{end_numerator}/meter_interval]) s ) \
                  AS aggregation FROM meter_records ORDER BY meter_serial, date;"
      results = ActiveRecord::Base.connection.raw_connection.exec sql
    end
  end


# Aggregating Weekly Usage from meter_records
  def aggregate_weekly_usage
#   Get the date of the first entry in the records -- we're doing all of them
    start_date = get_meter_records_start_date
#   Iterate through each week
    (1..53).each do |week|
      end_date = start_date + 6.days
#     Calculate the aggregations
      usage = aggregate_usage_between(start_date, end_date)
      start_date = start_date + 7.days
    end
  end

# Aggregating Monthly Usage from meter_records
  def aggregate_monthly_usage
#   Get the date of the first entry in the records
    start_date = get_meter_records_start_date
#   Iterate through 12 months
    (1..12).each do |month|
      end_date = start_date + 1.month - 1.day
#     Calculate the aggregations
      usage = aggregate_usage_between(start_date, end_date)
      start_date = start_date + 1.month
    end
  end

# Aggregating Quarterly Usage from meter_records
  def aggregate_quarterly_usage
#   Get the date of the first entry in the records
    start_date = get_meter_records_start_date
#   Iterate through 4 quarters
    (1..4).each do |quarter|
      end_date = start_date + 3.months - 1.day
#     Calculate the aggregations
      usage = aggregate_usage_between(start_date, end_date)
      start_date = start_date + 1.month
    end
  end

# Aggregating Yearly Usage from meter_records
  def aggregate_yearly_usage
#   Get the date of the first entry in the records
    start_date = get_meter_records_start_date
    end_date = start_date + 1.year - 1.day
 #  Calculate the aggregation
    usage = aggregate_usage_between(start_date, end_date)
  end


# Aggregating Weekly Usage from meter_aggregations
  def aggregate_weekly_usage_from_daily_aggregation
#   Get the date of the first entry in the records -- we're doing all of them
    start_date = get_meter_records_start_date
#   Iterate through each week
    (1..53).each do |week|
      end_date = start_date + 6.days
#     Calculate the aggregations
      usage = aggregate_usage_from_daily_aggregations_between(start_date, end_date)
    #MeterAggregation.where(:date => start_date..end_date).sum(:aggregation)

      start_date = start_date + 7.days
    end
  end


# Aggregating Weekly Usage from meter_aggregations
  def aggregate_weekly_usage_from_daily_aggregation_rails
#   Get the date of the first entry in the records -- we're doing all of them
    start_date = get_meter_records_start_date
#   Iterate through each week
    (1..53).each do |week|
      end_date = start_date + 6.days
      usage = 0
#     Calculate the aggregations
      (1..4).each do |i|
        aggregate_usage_from_daily_aggregations_between_rails start_date, end_date
      end
      #logger.info "Usage: #{usage}"
      start_date = start_date + 7.days
    end
  end


# Aggregating Monthly Usage from meter_aggregations
  def aggregate_monthly_usage_from_daily_aggregation
#   Get the date of the first entry in the records -- we're doing all of them
    start_date = get_meter_records_start_date
#   Iterate through 12 months
    (1..12).each do |month|
      end_date = start_date + 1.month - 1.day
#     Calculate the aggregations
      usage = aggregate_usage_from_daily_aggregations_between(start_date, end_date)
      start_date = start_date + 1.month
    end
  end


# Aggregating Monthly Usage from meter_aggregations
  def aggregate_monthly_usage_from_daily_aggregation_rails
#   Get the date of the first entry in the records -- we're doing all of them
    start_date = get_meter_records_start_date
#   Iterate through 12 months
    (1..12).each do |month|
      end_date = start_date + 1.month - 1.day
#     Calculate the aggregations
        usage = aggregate_usage_from_daily_aggregations_between_rails start_date, end_date
      start_date = start_date + 1.month
    end
  end


# Aggregating Monthly Usage from meter_aggregations
  def aggregate_monthly_usage_from_daily_aggregation_1_query
#   Get the date of the first entry in the records -- we're doing all of them
      sql = "SELECT to_char(date,'Mon') as month, start_time, end_time, meter_serial, SUM(aggregation) AS usage FROM meter_aggregations GROUP BY meter_serial, month, start_time, end_time ORDER BY meter_serial, month;"
#      sql = "SELECT meter_serial, SUM(aggregation) AS usage FROM meter_aggregations GROUP BY meter_serial ORDER BY meter_serial;"
      results = ActiveRecord::Base.connection.raw_connection.exec sql

      #log_pg_result results
  end


# Aggregating Quarterly Usage from meter_aggregations
  def aggregate_quarterly_usage_from_daily_aggregation
#   Get the date of the first entry in the records -- we're doing all of them
    start_date = get_meter_records_start_date
#   Iterate through 4 quarters
    (1..4).each do |quarter|
      end_date = start_date + 3.months - 1.day
#     Calculate the aggregations
      usage = aggregate_usage_from_daily_aggregations_between(start_date, end_date)
      start_date = start_date + 1.month
    end
  end


# Aggregating Quarterly Usage from meter_aggregations
  def aggregate_quarterly_usage_from_daily_aggregation_rails
#   Get the date of the first entry in the records -- we're doing all of them
    start_date = get_meter_records_start_date
#   Iterate through 4 quarters
    (1..4).each do |quarter|
      end_date = start_date + 3.months - 1.day
#     Calculate the aggregations
        usage = aggregate_usage_from_daily_aggregations_between_rails start_date, end_date
      start_date = start_date + 1.month
    end
  end


# Aggregating Yearly Usage from meter_aggregations
  def aggregate_yearly_usage_from_daily_aggregation
#   Get the date of the first entry in the records -- we're doing all of them
    start_date = get_meter_records_start_date
    end_date = start_date + 1.year - 1.day
 #  Calculate the aggregation
    usage = aggregate_usage_from_daily_aggregations_between(start_date, end_date)
  end


# Aggregating Yearly Usage from meter_aggregations
  def aggregate_yearly_usage_from_daily_aggregation_rails
#   Get the date of the first entry in the records -- we're doing all of them
    start_date = get_meter_records_start_date
    end_date = start_date + 1.year - 1.day
 #  Calculate the aggregation
    usage = aggregate_usage_from_daily_aggregations_between_rails start_date, end_date
  end

##
#  End Experiments
##



##
#  Experiment helper methods
##

# Get the first date in the records
  def get_meter_records_start_date
    sql = "SELECT date FROM meter_records ORDER BY date LIMIT 1"
    #results = ActiveRecord::Base.connection.exec_query(sql)
    results = ActiveRecord::Base.connection.raw_connection.exec sql
    results.each do |result|
      return Date.parse(result["date"])
    end
  end

# Aggregate data in the given range using meter_records
# Aggregates for all daily time periods given by Billing
  def aggregate_usage_between start_date, end_date
    aggregate_usage_from_daily_aggregations_between start_date, end_date
#   Get the time periods to aggregate from Billing
    billing_time_periods = Billing.time_periods

#   Calculate for each period
    billing_time_periods.each do |time_period|
      start_numerator = 30 * time_period[:start]
      end_numerator = 30 * time_period[:end]

      sql = "SELECT meter_serial, (SELECT SUM((SELECT SUM(s1) FROM \
              UNNEST(values[#{start_numerator}/meter_interval+1:#{end_numerator}/meter_interval]) s1 \
                GROUP BY meter_serial)) s2 GROUP BY meter_serial) AS usage FROM meter_records WHERE date >= '#{start_date}' \
                  AND date <= '#{end_date}' GROUP BY meter_serial ORDER BY meter_serial;"
      results = ActiveRecord::Base.connection.raw_connection.exec sql
#      results = ActiveRecord::Base.transaction { ActiveRecord::Base.connection.raw_connection.exec sql }
      #results = ActiveRecord::Base.connection.exec_query(sql)
      #render_resultset results
    end
  end
=begin
# Aggregate data in the given range using meter_aggreagations
# Aggregates for all daily time periods given by Billing
  def aggregate_usage_from_daily_aggregations_between start_date, end_date
#   Get the time periods to aggregate from Billing
    billing_time_periods = Billing.time_periods

#   Calculate for each period
    billing_time_periods.each do |time_period|
      #usage = MeterAggregation.where(:date => start_date..end_date, :start_time => time_period[:start], :end_time => time_period[:end]).sum(:aggregation)
      sql = "SELECT meter_serial, SUM(aggregation) AS usage FROM meter_aggregations WHERE date >= '#{start_date}' \
                  AND date <= '#{end_date}' AND start_time = #{time_period[:start]} AND end_time = #{time_period[:end]} GROUP BY meter_serial ORDER BY meter_serial;"

      #sql = "SELECT meter_serial from meter_aggregations;"
#      results = ActiveRecord::Base.connection.raw_connection.exec sql
      results = ActiveRecord::Base.connection.exec_query sql

      #log_pg_result results
    end
  end
=end
# Aggregate data in the given range using meter_aggreagations
# Aggregates for all daily time periods given by Billing
  def aggregate_usage_from_daily_aggregations_between start_date, end_date
#   Get the time periods to aggregate from Billing
    billing_time_periods = Billing.time_periods

#   Calculate for each period
    #billing_time_periods.each do |time_period|
      #usage = MeterAggregation.where(:date => start_date..end_date, :start_time => time_period[:start], :end_time => time_period[:end]).sum(:aggregation)
      sql = "SELECT meter_serial, start_time, end_time, SUM(aggregation) AS usage FROM meter_aggregations WHERE date >= '#{start_date}' \
                  AND date <= '#{end_date}' GROUP BY meter_serial, start_time, end_time ORDER BY meter_serial, start_time, end_time;"

      #sql = "SELECT meter_serial from meter_aggregations;"
#      results = ActiveRecord::Base.connection.raw_connection.exec sql
      results = ActiveRecord::Base.connection.exec_query sql

      #log_pg_result results
    #end
  end




# Rails

# Aggregate data in the given range using meter_aggreagations
# Aggregates for all daily time periods given by Billing
  def aggregate_usage_from_daily_aggregations_between_rails start_date, end_date
#   Get the time periods to aggregate from Billing
#    billing_time_periods = Billing.time_periods

    return MeterAggregation.where(:date => start_date..end_date).group("start_time", "end_time").sum(:aggregation)

#   Calculate for each period
#    billing_time_periods.each do |time_period|
#      usage = MeterAggregation.where(:date => start_date..end_date).sum(:aggregation)
#    end
  end

##
#  End Experiment helper methods
##


  def log_pg_result result
      logger.info "Result: #{result}"
      result.each do |row|
        logger.info "Row: #{row}"
      end
      logger.info "\n"
  end






















# Catch All
  def redirect_home
    redirect_to '/'
  end



  private

  def generated_data_directory
    return "GeneratedNEM12"
  end

  def minutes_in_day
    return 1440
  end




# Delete generated data
#
#######

  def delete_generated_files
    Dir.glob("#{generated_data_directory}/*.csv") do |file|
      File.delete(file)
    end
  end

# Generate Data
#
#######

  def generate_nem12

    from_participant_id = 'CNRGYMDP'
    to_participant_id = 'NEMMCO'
    date = DateTime.new(2001, 7, 1)
    nem12_s = 'NEM12'
    intervals = [1, 5, 10, 15, 30].shuffle
    serial = 2020

#   200 record options
    configuration = "E1Q1B1K1"
    register_id = "E1"
    meter_suffix = "Q1"
    mdm_data_stream_identifier = "N1"

#   300 record options
    quality_flags = ['A', 'E', 'F', 'N', 'S', 'V']
    quality_method_flags = []
    (11..18).each do |flag|
      quality_method_flags << flag
    end
    (52..56).each do |flag|
      quality_method_flags << flag
    end
    (61..65).each do |flag|
      quality_method_flags << flag
    end
    (71..74).each do |flag|
      quality_method_flags << flag
    end

    reason_codes = []
    (0..99).each do |code|
      reason_codes << code
    end

#   Meter options
    meters = []
    (0..4).each do |i|
      meters << {
        :meter => "NEM120#{serial}",
        :configuration => configuration,
        :register_id => register_id,
        :meter_suffix => meter_suffix,
        :mdm_data_stream_identifier => mdm_data_stream_identifier,
        :serial => (serial += 1),
        :uom => "KWH",
        :interval => intervals[i],
        :next_sceduled_read => (date + 7.days)
      }
    end


#   Create 53 week worth of data
    (1..53).each do |i|
      file_num = i.to_s.rjust(15, '0')
      filename = sprintf("%s/%s#%s#%s#%s.csv", generated_data_directory, nem12_s, file_num, from_participant_id, to_participant_id)
      #logger.info "file: #{filename}"
      File.open(filename, "w") do |csv|

#       Format the date
        date_s = nem12_date date+7.days

#       Write a 100 record
        nem12_100_record = sprintf("%d,%s,%s,%s,%s\n", 100, nem12_s, date_s, from_participant_id, to_participant_id)
        csv << nem12_100_record


        (1..7).each do |j|
          meters.each do |meter|
            nem12_200_record =  sprintf("%d,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
              200,
              meter[:meter],
              meter[:configuration],
              meter[:register_id],
              meter[:meter_suffix],
              meter[:mdm_data_stream_identifier],
              meter[:serial],
              meter[:uom],
              meter[:interval],
              nem12_date(date + 7.days)
            )
            csv << nem12_200_record

            reason_code = rand(100)

            nem12_300_record =  sprintf("%d,%s,%s,%s,%s,%s,%s,%s\n",
              300,
              nem12_date(date),
              generate_daily_usage(meter[:interval]),
              "#{quality_flags[rand(quality_flags.length)]}#{quality_method_flags[rand(quality_method_flags.length)]}",
              reason_code,
              reason_code_descriptions[reason_code],
              (date+1.days).strftime("%Y%m%d%H%M%S"),
              (date+7.days).strftime("%Y%m%d%H%M%S")
            )
            csv << nem12_300_record

          end # End meters
#         Increment the date
          date = date + 1.day
        end # End 7 days

        #send_file(filename)

      end # End writing csv

    end # End 53 weeks

  end

  def generate_daily_usage interval
    number_of_readings = minutes_in_day / interval
    readings = []
    (1..number_of_readings).each do |i|
      val = rand(500) + rand(Math::E..Math::PI)
      reading = sprintf("%.3f", val).to_f
      readings << reading
    end
    readings = readings.to_s.gsub(" ", "")
    return readings[1..(readings.length-2)]
  end

  def nem12_date date
    return date.strftime("%Y%m%d%H%M")
  end




# Import NEM12 fles to MeterRecord
#
#######

  def log_resultset results
      logger.info "#{results.length} results"
      i = 0
      results.each do |result|
        logger.info "--------> Result #{i+=1}: #{result}"
      end
  end

  def reason_code_descriptions
    return [
      "Free Text Description",
      "Meter/Equipment Changed",
      "Extreme Weather/Wet",
      "Quarantine",
      "Savage Dog",
      "Meter/Equipment Changed",
      "Extreme Weather/Wet",
      "Unable To Locate Meter",
      "Vacant Premise",
      "Meter/Equipment Changed",
      "Lock Damaged/Seized",
      "In Wrong Walk",
      "Locked Premises",
      "Locked Gate",
      "Locked Meter Box",
      "Access - Overgrown",
      "Noxious Weeds",
      "Unsafe Equipment/Location",
      "Read Below Previous",
      "Consumer Wanted",
      "Damaged Equipment/Panel",
      "Switched Off",
      "Meter/Equipment Seals Missing",
      "Meter/Equipment Seals Missing",
      "Meter/Equipment Seals Missing",
      "Meter/Equipment Seals Missing",
      "Meter/Equipment Seals Missing",
      "Meter/Equipment Seals Missing",
      "Damaged Equipment/Panel",
      "Relay Faulty/Damaged",
      "Meter Stop Switch On",
      "Meter/Equipment Seals Missing Damaged Equipment/Panel",
      "Relay Faulty/Damaged",
      "Meter Not In Handheld",
      "Timeswitch Faulty/Reset Required",
      "Meter High/Ladder Required",
      "Meter High/Ladder Required",
      "Unsafe Equipment/Location",
      "Reverse Energy Observed",
      "Timeswitch Faulty/Reset Required",
      "Faulty Equipment Display/Dials",
      "Faulty Equipment Display/Dials",
      "Power Outage",
      "Unsafe Equipment/Location",
      "Readings Failed To Validate",
      "Extreme Weather/Hot",
      "Refused Access",
      "Timeswitch Faulty/Reset Required",
      "Wet Paint",
      "Wrong Tariff",
      "Installation Demolished",
      "Access - Blocked",
      "Bees/Wasp In Meter Box",
      "Meter Box Damaged/Faulty",
      "Faulty Equipment Display/Dials",
      "Meter Box Damaged/Faulty",
      "Timeswitch Faulty/Reset Required",
      "Meter Ok - Supply Failure",
      "Faulty Equipment Display/Dials",
      "Illegal Connection/Equipment Tampered",
      "Meter Box Damaged/Faulty",
      "Damaged Equipment/Panel",
      "Illegal Connection/Equipment Tampered",
      "Key Required",
      "Wrong Key Provided",
      "Lock Damaged/Seized",
      "Extreme Weather/Wet",
      "Zero Consumption",
      "Reading Exceeds Estimate",
      "Probe Reports Tampering",
      "Probe Read Error",
      "Meter/Equipment Changed",
      "Low Consumption",
      "High Consumption",
      "Customer Read",
      "Communications Fault",
      "Estimation Forecast",
      "Null Data",
      "Power Outage Alarm",
      "Short Interval Alarm",
      "Long Interval Alarm",
      "CRC Error",
      "RAM Checksum Error",
      "ROM Checksum Error",
      "Data Missing Alarm",
      "Clock Error Alarm",
      "Reset Occurred",
      "Watchdog Timeout Alarm",
      "Time Reset Occurred",
      "Test Mode",
      "Load Control",
      "Added Interval (Data Correction) ",
      "Replaced Interval (Data Correction) ",
      "Estimated Interval (Data Correction)",
      "Pulse Overflow Alarm",
      "Data Out Of Limits",
      "Excluded Data",
      "Parity Error",
      "Energy Type (Register Changed)"
    ]
  end



end
