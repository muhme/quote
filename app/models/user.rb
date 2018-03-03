class User < ApplicationRecord

  has_many :quotations
  has_many :categories
  has_many :authors
  
  validates :login, presence: true, length: { maximum: 32 }, uniqueness: true
  validates :email, presence: true, length: { maximum: 64 }, uniqueness: false
  validates :crypted_password, presence: false, length: { maximum: 255 }, uniqueness: false
  validates :password_salt, presence: false, length: { maximum: 255 }, uniqueness: false

  acts_as_authentic do |c|
    c.transition_from_crypto_providers = [Authlogic::CryptoProviders::Sha512]
    c.crypto_provider = Authlogic::CryptoProviders::SCrypt # Upgrading to default new crypto provider, starting Authlogic 3.4.0
  end

  # count number of quotations created by the user
  def number_of_quotations
    return User.count_by_sql("select count(*) from quotations where user_id = #{self.id}")
  end

end