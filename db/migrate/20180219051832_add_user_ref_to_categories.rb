class AddUserRefToCategories < ActiveRecord::Migration[5.1]
  def change
    add_reference :categories, :user, foreign_key: true
  end
end
