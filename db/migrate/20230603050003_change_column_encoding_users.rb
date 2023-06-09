class ChangeColumnEncodingUsers < ActiveRecord::Migration[7.0]
  def up
    execute "ALTER TABLE users CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
    change_column :users, :email, :text, collation: "utf8mb4_general_ci", limit: 64
    change_column :users, :crypted_password, :text, collation: "utf8mb4_general_ci", limit: 256
    change_column :users, :password_salt, :text, collation: "utf8mb4_general_ci", limit: 256
    change_column :users, :persistence_token, :text, collation: "utf8mb4_general_ci", limit: 256
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
