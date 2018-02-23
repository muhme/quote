class AddPublicToQuotations < ActiveRecord::Migration[5.1]
  def change
    add_column :quotations, :public, :boolean, :default => false
  end
end
