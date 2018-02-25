class User < ApplicationRecord

  has_many :quotations
  has_many :categories
  has_many :authors
  
  validates :login, presence: true, length: { maximum: 32 }, uniqueness: true
  validates :email, presence: false, length: { maximum: 64 }, uniqueness: false
  validates :crypted_password, presence: false, length: { maximum: 255 }, uniqueness: false
  validates :password_salt, presence: false, length: { maximum: 32 }, uniqueness: false

  acts_as_authentic
  # acts_as_authentic do |c|
  #  c.my_config_option = my_value
  # end # the configuration block is optional

  # count number of quotations created by the user
  def number_of_quotations
    return User.count_by_sql("select count(*) from quotations where user_id = #{self.id}")
  end

end