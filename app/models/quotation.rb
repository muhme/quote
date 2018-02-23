class Quotation < ApplicationRecord
  
  belongs_to :user
  belongs_to :author
  has_and_belongs_to_many :categories
  
  validates :quotation, presence: true, length: { maximum: 512 }, uniqueness: true
  validates :source, presence: false, length: { maximum: 255 }, uniqueness: false
  validates :source_link, presence: false, length: { maximum: 255 }, uniqueness: false
  
end
