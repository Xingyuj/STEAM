class Site < ActiveRecord::Base

  belongs_to :user
  has_many :billing_sites, dependent: :destroy
  has_many :meters, through: :billing_sites

end
