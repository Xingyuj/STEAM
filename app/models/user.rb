class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :ftp_servers, dependent: :destroy
  has_many :sites
  has_many :billing_sites, through: :sites
  has_many :meters, through: :billing_sites

# This needs to be an actual instance of a User, not a class reference,
# and it should return the same one every time.
# Can we implement this method please?
  def self.authorised_user
    return User
  end

end
