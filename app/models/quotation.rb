class Quotation < ApplicationRecord

  belongs_to :user
  belongs_to :author
  has_and_belongs_to_many :categories
  
  validates :quotation, presence: true, length: { maximum: 512 }, uniqueness: true
  validates :source, presence: false, length: { maximum: 255 }, uniqueness: false
  validates :source_link, presence: false, length: { maximum: 255 }, uniqueness: false
  
  # count all non-public quotes
  def Quotation.count_non_public
    return count_by_sql("select count(*) from quotations where public = 0")
  end
  
  # returns - with links if exist - authors name and quotations source name or blank
  # returns "", "authors name", "source" or "authors name, source"
  #
  def get_linked_author_and_source
    my_source = self.source
    my_source = "<a href=\"#{self.source_link}\" target=\"quote_extern\">#{self.source}</a>" unless self.source.blank? or self.source_link.blank?
    ret = self.author ? self.author.get_linked_author_name_or_blank : ""
    ret += ", " unless ret.blank? or my_source.blank?
    ret += my_source unless my_source.blank?
    ret
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
    
  # returns authors name and source name or blank
  # returns "", "authors name", "source" or "authors name, source"
  #
  def get_author_and_source_name
    ret = get_author_name_or_blank
    ret += ", " unless ret.blank? or self.source.blank?
    ret += self.source unless self.source.blank?
    ret
  end
  
end
