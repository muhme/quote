class User < ApplicationRecord

  has_many :quotations
  has_many :categories
  has_many :authors
  
  validates :login, presence: true, length: { maximum: 32 }, uniqueness: true
  validates :email, presence: false, length: { maximum: 64 }, uniqueness: false
  validates :crypted_password, presence: false, length: { maximum: 32 }, uniqueness: false
  validates :salt, presence: false, length: { maximum: 32 }, uniqueness: false
  validates :remember_token, presence: false, length: { maximum: 32 }, uniqueness: false

  # count number of quotations created by the user
  def number_of_quotations
    return User.count_by_sql("select count(*) from quotations where user_id = #{self.id}")
  end

end