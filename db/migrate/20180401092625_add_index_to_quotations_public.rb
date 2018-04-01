class AddIndexToQuotationsPublic < ActiveRecord::Migration[5.1]
  def change
    add_index :quotations, :public, unique: false
  end
end
