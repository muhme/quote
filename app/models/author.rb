class Author < ApplicationRecord
  
  belongs_to :user
  has_many :quotations
  
  validates :name, presence: false, length: { maximum: 64 }, uniqueness: false
  validates :firstname, presence: false, length: { maximum: 64 }, uniqueness: false
  validates :link, presence: false, length: { maximum: 255 }, uniqueness: false
  validates :description, presence: false, length: { maximum: 255 }, uniqueness: false
  validate :first_or_last_name

  # count all non-public authors
  def Author.count_non_public
    return count_by_sql("select count(*) from authors where public = 0")
  end
  
  # gives an array with all author names initial chars, e.g. ["a", "b", "d" ...]
  def Author.init_chars
    a = Author.find_by_sql "select distinct substring(upper(trim(name)) from 1 for 1) as init from authors order by init"
    ret = []
    for i in 0..(a.length-1)
      ret[i] = a[i].nil? ? '*' : a[i].attributes['init']
      # cannot use map, must use gsub for multibyte-support (from ActiveSupport::Multibyte)
      ret[i] = ret[i].gsub('Ä','A')
      ret[i] = ret[i].gsub('Ö','O')
      ret[i] = ret[i].gsub('Ü','U')
      ret[i] = ret[i].gsub('ß','s')
      ret[i] = '*' unless ('A'..'Z').include?(ret[i])
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
    
  private

    def first_or_last_name
      if name.blank? and firstname.blank?
        errors.add(:base, "Vorname oder Nachname muss gesetzt sein")
      end
    end

end