class User < ApplicationRecord

  has_many :quotations
  has_many :categories
  has_many :authors
  
  validates :login, presence: true, length: { maximum: 32 }, uniqueness: true
  validates :email, presence: false, length: { maximum: 64 }, uniqueness: false
  validates :crypted_password, presence: false, length: { maximum: 32 }, uniqueness: false
  validates :salt, presence: false, length: { maximum: 32 }, uniqueness: false
  validates :remember_token, presence: false, length: { maximum: 32 }, uniqueness: false

end