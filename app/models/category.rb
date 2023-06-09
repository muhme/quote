class Category < ApplicationRecord
  extend Mobility
  translates :category, type: :string
  belongs_to :user
  has_and_belongs_to_many :quotations
  has_many :comments, as: :commentable
  before_destroy :check_quotes_and_comments
  validate :validate_category

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

  # gives an array with all existing categories names initial chars, e.g. ["a", "b", "d" ...]
  def Category.init_chars
    sql = <<-SQL
      SELECT DISTINCT SUBSTRING(UPPER(TRIM(value)), 1, 1) AS init
      FROM mobility_string_translations
      WHERE `key` = 'category' AND translatable_type = 'Category' AND locale = '#{I18n.locale}'
      ORDER BY init
      SQL
    a = Category.find_by_sql(sql)
    ret = []
    for i in 0..(a.length - 1)
      ret[i] = a[i].nil? ? "*" : a[i].attributes["init"]
      # cannot use map, must use gsub for multibyte-support (from ActiveSupport::Multibyte)
      ret[i] = ret[i].gsub("Ä", "A")
      ret[i] = ret[i].gsub("Ö", "O")
      ret[i] = ret[i].gsub("Ü", "U")
      ret[i] = ret[i].gsub("ß", "s")
      if I18n.locale == :uk
        ret[i] = "*" unless ("А".."Я").include?(ret[i])
      elsif I18n.locale == :ja
        if HIRAGANA.include?(ret[i])
          # ok
        elsif KATAKANA.include?(ret[i])
          ret[i] = HIRAGANA[KATAKANA.index(ret[i])]
        elsif HIRAGANA_DAKUTEN.include?(ret[i])
          ret[i] = HIRAGANA[HIRAGANA_DAKUTEN.index(ret[i])]
        elsif HIRAGANA_HANDAKUTEN.include?(ret[i])
          ret[i] = HIRAGANA[HIRAGANA_HANDAKUTEN.index(ret[i])]
        elsif KATAKANA_DAKUTEN.include?(ret[i])
          ret[i] = HIRAGANA[KATAKANA_DAKUTEN.index(ret[i])]
        elsif KATAKANA_HANDAKUTEN.include?(ret[i])
          ret[i] = HIRAGANA[KATAKANA_HANDAKUTEN.index(ret[i])]
        else
          ret[i] = "*"
        end
      else
        ret[i] = "*" unless ("A".."Z").include?(ret[i])
      end
    end
    ret.uniq
  end

  # search for category with starting letters without category_ids
  # and without category_ids entries (categories already selected)
  # returns always an Category array with 0...10 entries
  def self.filter_by_category(search, category_ids)
    return [] if search.blank?
    sql = "SELECT DISTINCT c.* from categories c "
    sql <<   "INNER JOIN mobility_string_translations mst " 
    sql <<   "ON c.id = mst.translatable_id "
    sql <<   "AND mst.translatable_type = 'Category' "
    sql <<   "AND mst.key = 'category' "
    sql <<   "AND mst.locale = '#{I18n.locale.to_s}' "
    sql <<   "AND mst.value LIKE '#{search}%' "
    sql <<   "AND mst.translatable_id NOT IN (#{category_ids.join(",")}) " if category_ids.present?
    sql <<   "ORDER BY mst.value LIMIT 10;"
    return Category.find_by_sql sql
  end

  # returns the category if the id is present, otherwise an empty string (e.g. id is 0 as marker for category isn't set)
  def Category.category_or_empty(id = nil)
    return Category.find(id).category
  rescue
    return ""
  end

  # Build list of recommenced categories from quotation.
  #
  # words, exluded from word matching without last or two last letters
  #
  EXCLUDED_WORDS = ["ei",   # prevents "ei" for "ein"/"eine"
                    "sein"] # "sein" for "seinem"
  # everthing are mapped to lowercase to compare
  # even compared with one or two letters less in the ending to find e.g. "Liebe" for "lieben" and "Spiel" for "spielen",
  # but not for EXLUDED_WORDS
  # German Umlaut (äöüß) are mapped to find e.g. "Kampf" for "kämpfen" or "süss" for "süßer"
  # quotation is Quotation object or String
  # return id list of categories found in quote
  def Category.check(quotation)
    ret = []
    quotation = quotation.quotation if quotation.is_a?(Quotation)
    if quotation.present?
      categories = Category.i18n.select(:id, :category).distinct
      categories.each do |category|
        category.category.downcase!
        category.category.tr!("äöü", "aou")
        category.category.gsub!("ß", "ss")
      end
      quotation.split(/[ ,.;\-—!?"'„”]/).map(&:downcase).each do |word|
        word.tr!("äöü", "aou")
        word.gsub!("ß", "ss")
        categories.each do |category|
          # category.category + "e" or "en" or "s" etc.
          w1 = EXCLUDED_WORDS.include?(word.chop) ? nil : word.chop
          w2 = EXCLUDED_WORDS.include?(word.chop.chop) ? nil : word.chop.chop
          ret |= [category.id] if word == category.category or w1 == category.category or w2 == category.category
        end
      end
    end
    return ret
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
end
