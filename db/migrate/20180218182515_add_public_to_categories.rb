class AddPublicToCategories < ActiveRecord::Migration[5.1]
  def change
    add_column :categories, :public, :boolean, :default => false
  end
end
