class Category < ApplicationRecord
  include ReusableMethods
  extend Mobility
  translates :category, type: :string
  belongs_to :user
  has_and_belongs_to_many :quotations
  has_many :comments, as: :commentable
  before_destroy :check_quotes_and_comments
  validate :validate_category
  after_save    :expire_category_init_chars_cache
  after_destroy :expire_category_init_chars_cache

  # words, exluded from word matching without last or two last letters
  EXCLUDED_WORDS_GERMAN =
    ["ei",           # prevents "das Ei" for "ein/eine"
     "sein"].freeze  # prevents "das Sein" for "seinem/seiner/seine"
  EXCLUDED_WORDS_ENGLISH =
    ["car",          # prevents "the car" for "cards" (but also disables "cars")
     "star",         # prevents "the star" for "start" (but also disables "stars")
     "plan"].freeze  # prevents "the plan" for "plant"

  # doing Mobility case-insensitive search on category
  # returns a Category::ActiveRecord_Relation or nil
  scope :search_case_insensitive, ->(category_looking_for) do
                                    i18n do
                                      category.lower.matches("#{category_looking_for.downcase}")
                                    end
                                  end

  # count all non-public categories
  def Category.count_non_public
    return count_by_sql("select count(*) from categories where public = 0")
  end

  # gives an array with all existing categories names initial chars plus '*' if no mapping exists
  # e.g. ["a", "b", "d" ... "z", "*"]
  def Category.init_chars
    Rails.cache.fetch('category_init_chars', expires_in: 1.hours) do
      # Fetch all category names in the current locale
      category_names = Category.i18n.select(:category).distinct.pluck(:category)
      # Extract the initial character of each category name, map to base letter, and eliminate doubled entries
      category_names.compact.map { |category| base_letter(category[0].upcase) }.uniq
    end
  end

  # search for category with starting letters without category_ids
  # and without category_ids entries (categories already selected)
  # returns always an Category array with 0...10 entries
  def self.filter_by_category(search, category_ids)
    return [] if search.blank?

    sql = "SELECT DISTINCT c.* from categories c "
    sql << "INNER JOIN mobility_string_translations mst "
    sql << "ON c.id = mst.translatable_id "
    sql << "AND mst.translatable_type = 'Category' "
    sql << "AND mst.key = 'category' "
    sql << "AND mst.locale = '#{I18n.locale.to_s}' "
    sql << "AND mst.value LIKE '#{search}%' "
    sql << "AND mst.translatable_id NOT IN (#{category_ids.join(",")}) " if category_ids.present?
    sql << "ORDER BY mst.value LIMIT 10;"
    return Category.find_by_sql sql
  end

  # returns the category if the id is present, otherwise an empty string (e.g. id is 0 as marker for category isn't set)
  def Category.category_or_empty(id = nil)
    category = Category.find(id).category
    return category.nil? ? "" : category
  rescue
    return ""
  end

  # Build list of recommenced categories from quotation.
  #
  # quotation is Quotation object or String
  # return id list of categories found in quote
  def self.check(quotation)
    quotation = quotation.quotation if quotation.is_a?(Quotation)
    if quotation.present?
      ids_and_categories = Category.i18n.distinct.pluck(:id, :category)
      case I18n.locale
      when :ja
        ret = check_japanese(quotation, ids_and_categories)
      when :de
        ret = check_german(quotation, ids_and_categories)
      else
        ret = check_american_english(quotation, ids_and_categories)
        # if needed we can implement :es and :uk
      end
    end
    ret.nil? ? [] : ret.uniq
  end

  private

  # doing validation by own with Mobility
  # validates :category, presence: true, length: { maximum: 64 }, uniqueness: { case_sensitive: false }
  def validate_category
    current_locale = Mobility.locale.to_s
    category_in_locale = category(locale: current_locale)

    # presence validation
    if category_in_locale.blank?
      errors.add(:category, :blank)
    end

    if category_in_locale.present?
      # length validation
      if category_in_locale.length > 64
        errors.add(:category, :too_long, count: 64)
      end

      # case-insensitive uniqueness validation
      if new_record? or attribute_changed?(:category)
        already_existing = Category.search_case_insensitive(category_in_locale)
        if already_existing.present?
          errors.add(:category, :taken, value: already_existing.first.category(locale: current_locale))
        end
      end
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

  def expire_category_init_chars_cache
    Rails.cache.delete('category_init_chars_cache')
  end

  class << self # opens up the singleton class to define private class methods as only private applies to instance and not to class methods
    private

    # In Japanese, there are no spaces to separate words, so we just have to go through each character one by one.
    def check_japanese(quotation, ids_and_categories)
      # sort the list of categories for length to find e.g. "時間厳守" (punctuality) before "時間" (time)
      ids_and_categories.sort_by! { |_, category| -category.to_s.length }
      ret = []
      i = 0
      while i < quotation.length
        match_found = false
        ids_and_categories.each do |id, category|
          next if category.blank? # Skip empty or nil categories

          if quotation[i, category.length] == category
            ret << id
            i += category.length
            match_found = true
            break
          end
        end
        i += 1 unless match_found
      end
      ret
    end

    # everthing is mapped to lowercase to compare
    # even compared with one or two letters less in the ending to find e.g. "Liebe" for "lieben" and "Spiel" for "spielen",
    # but not for excluded_words
    # German Umlaut (äöü) and sharp S (ß) are mapped to find e.g. "Kampf" for "kämpfen" or "süss" for "süßer"
    def check_german(quotation, ids_and_categories)
      ret = []
      # create a lowercase list of words
      words = quotation.split(/[ ,.;\-—!?"'„”]/).map(&:downcase).reject(&:blank?)

      ids_and_categories.each do |id, category|
        next if category.blank? # Skip empty or nil categories

        category.downcase!
        category.tr!("äöü", "aou")
        category.gsub!("ß", "ss")
        words.each do |word|
          next if word.blank? # Skip empty words or punctuation marks

          word.tr!("äöü", "aou")
          word.gsub!("ß", "ss")
          # prevents e.g. "ei" for "ein"
          next if EXCLUDED_WORDS_GERMAN.include?(word.chop)
          # prevents e.g. "ei" for "eine" or "sein" for "seinem"
          next if EXCLUDED_WORDS_GERMAN.include?(word.chop.chop)

          # finds identical and also e.g. "Liebe" for "lieben" and "Spiel" for "spielen",
          ret << id if word == category || word.chop == category || word.chop.chop == category
        end
      end
      ret
    end

    # everthing is mapped to lowercase to compare
    # even compared with one or two letters less in the ending to find e.g. "German" for "Germany" and "time" for "timely",
    # but not for excluded_words
    def check_american_english(quotation, ids_and_categories)
      ret = []
      # create a lowercase list of words
      words = quotation.split(/[ ,.;\-—!?"'„”]/).map(&:downcase).reject(&:blank?)

      ids_and_categories.each do |id, category|
        next if category.blank? # Skip empty or nil categories

        category.downcase!
        words.each do |word|
          next if word.blank? # Skip empty words or punctuation marks
          # prevents e.g. "plan" for "plant"
          next if EXCLUDED_WORDS_ENGLISH.include?(word.chop)
          # prevents e.g. "car" for "cards"
          next if EXCLUDED_WORDS_ENGLISH.include?(word.chop.chop)

          # finds identical and also e.g. "Liebe" for "lieben" and "Spiel" for "spielen",
          ret << id if word == category || word.chop == category || word.chop.chop == category
        end
      end
      ret
    end
  end
end
