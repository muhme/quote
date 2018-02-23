class AddUserRefToAuthors < ActiveRecord::Migration[5.1]
  def change
    add_reference :authors, :user, foreign_key: true
  end
end
