class Category < ApplicationRecord
  
  belongs_to :user
  has_and_belongs_to_many :quotations
  has_many :comments, as: :commentable
  before_destroy :check_quotes_and_comments
  validates :category, presence: true, length: { maximum: 64 }, uniqueness: { case_sensitive: false }

  # count all non-public categories
  def Category.count_non_public
    return count_by_sql("select count(*) from categories where public = 0")
  end

  # gives an array with all categories names initial chars, e.g. ["a", "b", "d" ...]
  def Category.init_chars
    a = Category.find_by_sql "select distinct substring(upper(trim(category)) from 1 for 1) as init from categories order by init"
    ret = []
    for i in 0..(a.length - 1)
      ret[i] = a[i].nil? ? "*" : a[i].attributes["init"]
      # cannot use map, must use gsub for multibyte-support (from ActiveSupport::Multibyte)
      ret[i] = ret[i].gsub("Ä", "A")
      ret[i] = ret[i].gsub("Ö", "O")
      ret[i] = ret[i].gsub("Ü", "U")
      ret[i] = ret[i].gsub("ß", "s")
      ret[i] = "*" unless ("A".."Z").include?(ret[i])
    end
    ret
  end

  # search for category with starting letters without category_ids
  # and without category_ids entries (categories already selected)
  # returns always an Category array with 0...10 entries
  def Category.filter_by_category(search, category_ids)
    return [] if search.blank?
    sql = "SELECT * from categories where category LIKE '#{search}%'"
    sql << " AND id NOT IN (#{category_ids.join(",")})" if category_ids.present?
    sql << " ORDER BY category LIMIT 10;"
    return Category.find_by_sql sql
  end

  # return category if id is exists, otherwise an empty string any other case (e.g. id is 0 as flag for category isn't set)
  def Category.category_or_empty(id = nil)
    return Category.find(id).category
  rescue
    return ""
  end

  # Build list of recommenced categries from quotation.
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
      categories = Category.select(:id, :category).distinct
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
