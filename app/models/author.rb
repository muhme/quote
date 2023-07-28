class Author < ApplicationRecord
  include ReusableMethods
  extend Mobility
  translates :firstname, type: :string
  translates :name, type: :string
  translates :description, type: :string
  translates :link, type: :string
  belongs_to :user
  has_many :quotations
  has_many :comments, as: :commentable
  before_save :unescape_link
  before_destroy :check_quotes_and_comments
  validates :name, presence: false, length: { maximum: 64 }, uniqueness: false
  validates :firstname, presence: false, length: { maximum: 64 }, uniqueness: false
  validates :link, presence: false, length: { maximum: 255 }, uniqueness: false
  validates :description, presence: false, length: { maximum: 255 }, uniqueness: false
  validate :first_or_last_name
  after_save    :expire_author_init_chars_cache
  after_destroy :expire_author_init_chars_cache

  # count all non-public authors
  def Author.count_non_public
    return count_by_sql("select count(*) from authors where public = 0")
  end

  # gives an array with initial letters from all existing author names plus '*' if no mapping exists
  # e.g. ["A", "C", "D" ... "*"]
  def Author.init_chars
    Rails.cache.fetch('author_init_chars', expires_in: 1.hours) do
      # Fetch all category names in the current locale
      author_names = Author.i18n.select(:name).distinct.pluck(:name)
      # Extract the initial character of each category name, map to base letter, and eliminate doubled entries
      author_names.compact.map { |name| base_letter(name[0].upcase) }.uniq
    end
  end

  # returns authors name or blank
  # returns "", "firstname", "lastname" or "firstname lastname"
  #
  def get_author_name_or_blank
    ret = ""
    ret += firstname unless firstname.blank?
    ret += " " unless firstname.blank? or name.blank?
    ret += name unless name.blank?
    ret
  end

  # returns authors name, linked if possible, or blank
  # returns "", "firstname", "lastname" or "firstname lastname"
  # TODO: adopt for japanese w/o space, btw where used, really needed?
  #
  def get_linked_author_name_or_blank
    ret = get_author_name_or_blank
    ret = "<a href=\"#{self.link}\" target=\"quote_extern\">#{ret}</a>" unless ret.blank? or self.link.blank?
    ret
  end

  # gives last name comma separated from first name
  # w/o comma if first or last name is missing
  # gives an empty string if first and last name are missing
  # e.g. gives "Einstein, Albert" or only lastname "Sokrates" or only firstname "Karl" or ""
  def last_first_name
    ret = ""
    ret += name unless name.blank?
    ret += ", " unless firstname.blank? or name.blank?
    ret += firstname unless firstname.blank?
    ret
  end

  # search for "name, firstname, description" e.g.
  # Gandhi, Mahatma, indischer Rechtsanwalt, Pazifist, Staatsführer (1869 - 1948)
  # returns always an Authors array with 0...10 entries
  def Author.filter_by_name_firstname_description(search)
    return [] if search.blank?

    name, firstname, description = search.split(",", 3)

    # Build the base query
    authors = Author.joins(
      "LEFT JOIN mobility_string_translations name_translations
          ON authors.id = name_translations.translatable_id
          AND name_translations.translatable_type = 'Author'
          AND name_translations.key = 'name'
          AND name_translations.locale = '#{I18n.locale}'",
      "LEFT JOIN mobility_string_translations firstname_translations
          ON authors.id = firstname_translations.translatable_id
          AND firstname_translations.translatable_type = 'Author'
          AND firstname_translations.key = 'firstname'
          AND firstname_translations.locale = '#{I18n.locale}'",
      "LEFT JOIN mobility_string_translations description_translations
          ON authors.id = description_translations.translatable_id
          AND description_translations.translatable_type = 'Author'
          AND description_translations.key = 'description'
          AND description_translations.locale = '#{I18n.locale}'"
    )

    # Apply filters based on the search criteria
    authors = authors.where("name_translations.value LIKE ?", "#{name}%") if name.present?
    authors = authors.where("firstname_translations.value LIKE ?", "#{firstname.lstrip}%") if firstname.present?
    authors = authors.where("description_translations.value LIKE ?", "#{description.lstrip}%") if description.present?

    # Limit and order the results
    authors.limit(10).order("name_translations.value")
  end

  private

  def first_or_last_name
    if name.blank? and firstname.blank?
      errors.add(:base, :first_or_last_name_needed)
    end
  end

  # don't delete categories with quotes or comments
  def check_quotes_and_comments
    if quotations.any?
      errors.add :base, :has_quotes
      throw :abort
    end
    if comments.any?
      errors.add :base, :has_comments
      throw :abort
    end
  end

  def expire_author_init_chars_cache
    Rails.cache.delete('author_init_chars_cache')
  end

  # often by cut&paste from browser URL decode is needed and not damaging
  def unescape_link
    self.link = CGI.unescape(link) if self.link.present?
  end
end
