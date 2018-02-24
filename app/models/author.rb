class Author < ApplicationRecord
  
  belongs_to :user
  has_many :quotations
  
  validates :name, presence: true, length: { maximum: 64 }, uniqueness: false
  validates :firstname, presence: false, length: { maximum: 64 }, uniqueness: false
  validates :link, presence: false, length: { maximum: 255 }, uniqueness: false
  validates :description, presence: false, length: { maximum: 255 }, uniqueness: false

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

end