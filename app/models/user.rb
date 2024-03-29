class User < ApplicationRecord
  has_many :quotations
  has_many :categories
  has_many :authors
  has_many :comments

  # EMAIL_NONASCII copied from authlogic-4.4.3/lib/authlogic/regex.rb as is deprecated/deleted
  #
  # A draft regular expression for internationalized email addresses. Given
  # that the standard may be in flux, this simply emulates @email_regex but
  # rather than allowing specific characters for each part, it instead
  # disallows the complement set of characters:
  #
  # - email_name_regex disallows: @[]^ !"#$()*,/:;<=>?`{|}~\ and control characters
  # - domain_head_regex disallows: _%+ and all characters in email_name_regex
  # - domain_tld_regex disallows: 0123456789- and all characters in domain_head_regex
  #
  # http://en.wikipedia.org/wiki/Email_address#Internationalization
  # http://tools.ietf.org/html/rfc6530
  # http://www.unicode.org/faq/idn.html
  # http://ruby-doc.org/core-2.1.5/Regexp.html#class-Regexp-label-Character+Classes
  # http://en.wikipedia.org/wiki/Unicode_character_property#General_Category
  EMAIL_NONASCII = /
    \A
    [^[:cntrl:][@\[\]\^ \!"\#$\(\)*,\/:;<=>?`{|}~\\]]+                        # mailbox
    @
    (?:[^[:cntrl:][@\[\]\^ \!\"\#$&\(\)*,\/:;<=>\?`{|}~\\_.%+']]+\.)+         # subdomains
    (?:[^[:cntrl:][@\[\]\^ \!\"\#$&\(\)*,\/:;<=>\?`{|}~\\_.%+\-'0-9]]{2,25})  # TLD
    \z
  /x

  # \A start of the string
  # [[:alnum:] .\-_@+] any alphanumeric character, space, dot, dash, underscore, at symbol or plus
  # + one or more times.
  # \z end of the string
  # LOGIN = /\A[[:alnum:]_][[:alnum:]\.+\-_@ ]+\z/
  # LOGIN = /\A[^[:cntrl:][@\[\]\^\!"\#$\(\)*,\/:;<=>?`{|}~\\]]+\z/
  LOGIN = /\A[[:alnum:]_][[:alnum:] .\-_@+]+\z/

  validates :email,
            format: {
              with: EMAIL_NONASCII,
              message: proc {
                ::Authlogic::I18n.t(
                  "error_messages.email_invalid",
                  default: "should look like an email address.",
                )
              },
            },
            length: { maximum: 64 },
            uniqueness: { case_sensitive: false }

  validates :login,
            format: {
              with: LOGIN,
              message: proc {
                ::Authlogic::I18n.t(
                  "error_messages.login_invalid",
                  default: "should use only letters, numbers, spaces, and .-_@+ please.",
                )
              },
            },
            length: { within: 3..32 },
            uniqueness: { case_sensitive: false }

  validates :password,
            confirmation: { if: :require_password? },
            length: {
              minimum: 8,
              if: :require_password?,
            }
  validates :password_confirmation,
            length: {
              minimum: 8,
              if: :require_password?,
            }

  validates :crypted_password, presence: false, length: { maximum: 255 }, uniqueness: false
  validates :password_salt, presence: false, length: { maximum: 255 }, uniqueness: false

  acts_as_authentic do |c|
    c.crypto_provider = ::Authlogic::CryptoProviders::SCrypt
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    UserMailer.password_reset(self).deliver_now
  end

  # count number of quotations created by the user
  def number_of_quotations
    return User.count_by_sql("select count(*) from quotations where user_id = #{self.id}")
  end

  # get users with quotations or comments
  scope :with_quotations_or_comments, -> {
    left_joins(:quotations, :comments)
      .where("quotations.user_id IS NOT NULL OR comments.user_id IS NOT NULL")
      .distinct
  }

  # a password check is required for new users who have never set a password before,
  # or if one of the password fields is set
  def require_password?
    password.present? || password_confirmation.present? || crypted_password.blank?
  end
end
