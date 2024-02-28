class Quotation < ApplicationRecord
  belongs_to :user
  belongs_to :author
  has_and_belongs_to_many :categories
  has_many :comments, as: :commentable
  before_validation :convert_empty_strings_to_nil
  before_destroy :check_comments
  validates :quotation, presence: true, length: { maximum: 512 }, uniqueness: { case_sensitive: false }
  validates :source, presence: false, length: { maximum: 255 }, uniqueness: false
  validates :source_link, presence: false, length: { maximum: 255 }, uniqueness: false
  validates :locale, presence: true

  # count all non-public quotes
  def Quotation.count_non_public
    return count_by_sql("select count(*) from quotations where public = 0")
  end

  def Quotation.count_users_quotations(user_id)
    Quotation.count_by_sql("select count(*) from quotations where user_id = #{user_id}")
  end

  def get_author_name_or_blank
    self.author ? self.author.get_author_name_or_blank : ""
  end

  # returns authors name and source name or blank
  # returns "", "authors name", "source" or "authors name, source"
  #
  def get_author_and_source_name
    ret = get_author_name_or_blank
    ret += ", " unless ret.blank? or self.source.blank?
    ret += self.source unless self.source.blank?
    ret
  end

  # returns list of quotations
  # can be reduced by pattern or by locales
  # sorted by created_at
  def self.search_by_pattern_and_locales(pattern, locales)
    if pattern.present?
      quotations = where("quotation LIKE ?", "%#{pattern}%").order(created_at: :desc)
    else
      quotations = all.order(created_at: :desc)
    end
    quotations = quotations.where(locale: locales) if locales.present?
    quotations
  end

  # returns list of quotations of the given author ID and
  # can be reduced by locales
  # sorted by created_at
  def self.by_author_and_locales(author_id, locales = nil)
    quotations = where(author_id: author_id).order(created_at: :desc)
    quotations = quotations.where(locale: locales) if locales.present?
    quotations
  end

  # returns list of quotations of the given category ID and
  # can be reduced by locales
  # sorted by created_at
  def self.by_category_and_locales(category_id, locales = nil)
    quotations = joins(:categories).where(categories: { id: category_id }).distinct.order(created_at: :desc)
    quotations = quotations.where(locale: locales) if locales.present?
    quotations
  end

  # returns list of non-public quotations and
  # can be reduced by locales
  # sorted by created_at
  def self.not_public_and_by_locales(locales = nil)
    quotations = where(public: 0).order(created_at: :desc)
    quotations = quotations.where(locale: locales) if locales.present?
    quotations
  end

  private

  # source and source_link are optional and saved as NULL in database if blank
  def convert_empty_strings_to_nil
    self.source      = nil if self.source.blank?
    self.source_link = nil if self.source_link.blank?
  end

  # don't delete quotes with comments
  def check_comments
    if comments.any?
      errors.add :base, :has_comments
      throw :abort
    end
  end
end
