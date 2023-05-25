class Author < ApplicationRecord
  belongs_to :user
  has_many :quotations
  has_many :comments, as: :commentable
  before_destroy :check_quotes_and_comments
  validates :name, presence: false, length: { maximum: 64 }, uniqueness: false
  validates :firstname, presence: false, length: { maximum: 64 }, uniqueness: false
  validates :link, presence: false, length: { maximum: 255 }, uniqueness: false
  validates :description, presence: false, length: { maximum: 255 }, uniqueness: false
  validate :first_or_last_name

  # count all non-public authors
  def Author.count_non_public
    return count_by_sql("select count(*) from authors where public = 0")
  end

  # gives an array with initial letters from all existing author names, e.g. ["A", "C", "D" ...]
  def Author.init_chars
    a = Author.find_by_sql "select distinct substring(upper(trim(name)) from 1 for 1) as init from authors order by init"
    ret = []
    for i in 0..(a.length - 1)
      ret[i] = a[i].nil? ? "*" : a[i].attributes["init"]
      ret[i] = "A" if ret[i] == "Ä"
      ret[i] = "O" if ret[i] == "Ö"
      ret[i] = "U" if ret[i] == "Ü"
      ret[i] = "S" if ret[i] == "ß"
      ret[i] = "*" unless ("A".."Z").include?(ret[i])
    end
    ret
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
    sql = "SELECT * from authors where name LIKE '#{name}%'"
    sql << " AND firstname LIKE '#{firstname.lstrip}%'" if firstname.present?
    sql << " AND description LIKE '#{description.lstrip}%'" if description.present?
    sql << " ORDER BY name LIMIT 10;"
    return Author.find_by_sql sql
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

end
