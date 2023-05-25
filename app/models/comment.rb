class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  validates :comment, presence: true, length: { maximum: 512 }

  def self.number_of(o)
    where(commentable_type: o.class.to_s, commentable_id: o.id).count
  end

  def editable_by(user)
    user && user.id && ((user.id == self.user_id) || user.admin)
  end

end
