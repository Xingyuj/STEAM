class RetailPlan < ActiveRecord::Base

  #List of all validations for Retail plan during both create and update
  validate :value_presence
  validates :discount, numericality: {less_than_or_equal_to: 1, greater_than_or_equal_to: 0}
  validate :date_clashes

  belongs_to :billing_site
  belongs_to :retailer

  # after using the gem 'active_record-acts_as'
  has_many :charge_factories, dependent: :destroy
  has_many :daily_usage_charges
  has_many :global_usage_charges
  has_many :metering_charges
  has_many :supply_charges
  has_many :certificate_charges
  has_many :capacity_charges
  has_many :invoices, dependent: :destroy

  accepts_nested_attributes_for :daily_usage_charges, update_only: true
  accepts_nested_attributes_for :global_usage_charges, update_only: true
  accepts_nested_attributes_for :metering_charges, update_only: true
  accepts_nested_attributes_for :supply_charges, update_only: true
  accepts_nested_attributes_for :charge_factories, update_only: true
  accepts_nested_attributes_for :certificate_charges, update_only: true
  accepts_nested_attributes_for :capacity_charges, update_only: true

  #Validation methods
  def value_presence
    if name.blank?
      logger.info "........------....... Name Blank"
      errors.add(:name, "Cannot be blank")
    end
  end

  #Validation methods
  def date_clashes
    if start_date > end_date
      logger.info "........------....... Start less than End date"
      errors.add(:start_date, "Cannot be later than the End date")
    end
  end


  # Assign Retail Plan ID to daily usage charges
  def daily_usage_charges
    DailyUsageCharge.where(retail_plan_id: self)
  end
  # Assign Retail Plan ID to global usage charges
  def global_usage_charges
    GlobalUsageCharge.where(retail_plan_id: self)
  end
  # Assign Retail Plan ID to metering charges
  def metering_charges
    MeteringCharge.where(retail_plan_id: self)
  end
  # Assign Retail Plan ID to supply charges
  def supply_charges
    SupplyCharge.where(retail_plan_id: self)
  end
  # Assign Retail Plan ID to certificate charges
  def certificate_charges
    CertificateCharge.where(retail_plan_id: self)
  end
  # Assign Retail Plan ID to capacity charges
  def capacity_charges
    CapacityCharge.where(retail_plan_id: self)
  end


  # Return daily time periods for prediction method(Start and end time of Daily usage charges of retail plans associated with the meter)
  def self.dailyTimePeriods meters
    dtp =[]

    #Assign the latest Retail Plan
    retail_plan = RetailPlan.last

    #Assign the daily usage charges of the latest retail plan
    @daily = retail_plan.daily_usage_charges
    @daily.each do |daily_usage|
      dtp << ( { :start_time => daily_usage.start_time, :end_time => daily_usage.end_time, :label => daily_usage.name})
    end
    return dtp.to_a
  end


  # Return daily time periods (Start and end time of Daily usage charges of retail plans)
  # Reloaded dailyTimePeriods without parameter
  # Return: [Hash(:start_time, value),Hash(:end_time, value)]
  def daily_time_periods
    daily_time_periods = []
    @daily_usage_charges = self.daily_usage_charges
    @daily_usage_charges.each do |daily_usage_charge|
      daily_time_periods << {start_time: daily_usage_charge.start_time, end_time: daily_usage_charge.end_time}
    end
    return daily_time_periods
  end


  # Daily time periods for Metering system
  def self.daily_time_periods meters
    #   Defining as a set guarantees unique values...
    daily_time_periods = Set.new []
    DailyUsageCharge.all.each do |duc|
      daily_time_periods.add ( { :start_time => duc.start_time, :end_time => duc.end_time, :label => duc.name } )
    end
    #   ... but return as array
    return daily_time_periods.to_a
  end


  # Returns an array containing the ChargeFactories used by this RetailPlan
  def chargefactories
    charge_factory_are_used = []
    self.charge_factories.each do |charge_factory|
      charge_factory_are_used << charge_factory
    end
    return charge_factory_are_used
  end


  # Returns an array of the meters that are used by this RetailPlan
  def meters
    meters_are_used = []
    self.billing_site.meters.each do |meter|
      meters_are_used << meter
    end
    return meters_are_used
  end


  # Returns an array of billing periods,
  # for which the system is able to provide predicted data
  def predictable_billing_periods
    time_periods = []
    #decide the increment time period
    if self.billing_interval == "Monthly"
      incrementBy = 1.month
    elsif self.billing_interval == "Quarterly"
      incrementBy = 3.months
    else
      return "No billing interval record!"
    end

    #get the first period of the predictable period list
    currentStartDate = self.invoices.where(actable_type: ImportedInvoice).last[:end_date] + 1.day
    currentEndDate = currentStartDate + incrementBy
    time_periods << {:start_date => currentStartDate, :end_date => currentEndDate}

    #calculate the end of the NEXT Financial year
    currentYear = currentStartDate.year
    eonfy = Date.new(currentYear,06,30)
    if (currentStartDate - 1.day).month <= 6
      eonfy = eonfy + 1.year
    else
      eonfy = eonfy + 2.year
    end

    #insert the remain periods of the predictable period 
    while  currentEndDate < eonfy
      currentStartDate = currentEndDate + 1.day
      currentEndDate = currentEndDate + incrementBy
      time_periods << {:start_date => currentStartDate, :end_date => currentEndDate}
    end

    return time_periods
 end
end
