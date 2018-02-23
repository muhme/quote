class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :login, :limit => 32, :null => false
      t.string :email, :limit => 64
      t.boolean :admin, :default => false
      t.string :crypted_password, :limit => 32
      t.string :salt, :limit => 32
      t.string :remember_token, :limit => 32
      t.datetime :remember_token_expires_at
      t.timestamps
    end
  end
end
