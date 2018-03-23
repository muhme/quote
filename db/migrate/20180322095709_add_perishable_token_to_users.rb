class AddPerishableTokenToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :perishable_token, :string, :default => "", :null => false
    add_index :users, :perishable_token
  end
end
