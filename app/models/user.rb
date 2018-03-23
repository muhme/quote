class User < ApplicationRecord

  has_many :quotations
  has_many :categories
  has_many :authors
  
  validates :login, presence: true, length: { maximum: 32 }, uniqueness: true
  validates :email, presence: true, length: { maximum: 64 }, uniqueness: false
  validates :crypted_password, presence: false, length: { maximum: 255 }, uniqueness: false
  validates :password_salt, presence: false, length: { maximum: 255 }, uniqueness: false

  acts_as_authentic do |c|
    # allow non-ASCCI characters (e.g. äöü) in email address
    c.validates_format_of_email_field_options = {:with => Authlogic::Regex.email_nonascii}
    # disable login field checks (e.g. allow spaces), only used temporary for manual testing, not enabled for new user on production
    # c.validate_login_field = false
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    UserMailer.password_reset(self).deliver_now
  end

  # count number of quotations created by the user
  def number_of_quotations
    return User.count_by_sql("select count(*) from quotations where user_id = #{self.id}")
  end

end