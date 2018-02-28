class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|

      # Authlogic::ActsAsAuthentic::Email
      t.string    :email, :limit => 64

      # Authlogic::ActsAsAuthentic::Password
      t.string    :crypted_password
      t.string    :password_salt

      # Authlogic::ActsAsAuthentic::PersistenceToken
      t.string    :persistence_token

      # Authlogic::Session::MagicStates
      t.boolean   :active, default: false
      t.boolean   :approved, default: false
      t.boolean   :confirmed, default: false

      # Authlogic::Session::MagicColumns, the only one selected
      t.datetime  :last_login_at

      t.timestamps
      
      # my extensions to authlogic
      t.string :login, :limit => 32, :null => false
      t.boolean :admin, :default => false
      
    end
  end
end
