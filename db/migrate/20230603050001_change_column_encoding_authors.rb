class ChangeColumnEncodingAuthors < ActiveRecord::Migration[7.0]
  def up
    execute "ALTER TABLE authors CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
    change_column :authors, :name, :text, collation: "utf8mb4_general_ci", limit: 64
    change_column :authors, :firstname, :text, collation: "utf8mb4_general_ci", limit: 64
    change_column :authors, :description, :text, collation: "utf8mb4_general_ci", limit: 256
    change_column :authors, :link, :text, collation: "utf8mb4_general_ci", limit: 256
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
