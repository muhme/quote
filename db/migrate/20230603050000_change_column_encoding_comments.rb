class ChangeColumnEncodingComments < ActiveRecord::Migration[7.0]
  def up
    execute "ALTER TABLE comments CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
    change_column :comments, :comment, :text, collation: "utf8mb4_general_ci", limit: 512
    change_column :comments, :locale, :text, collation: "utf8mb4_general_ci", limit: 8
    change_column :comments, :commentable_type, :text, collation: "utf8mb4_general_ci", limit: 16
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
