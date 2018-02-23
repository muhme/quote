class AddPublicToAuthors < ActiveRecord::Migration[5.1]
  def change
    add_column :authors, :public, :boolean, :default => false
  end
end
