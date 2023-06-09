class ChangeColumnEncodingQuotations < ActiveRecord::Migration[7.0]
  def up
    execute "ALTER TABLE quotations CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
    change_column :quotations, :quotation, :text, collation: "utf8mb4_general_ci", limit: 512
    change_column :quotations, :source, :text, collation: "utf8mb4_general_ci", limit: 256
    change_column :quotations, :source_link, :text, collation: "utf8mb4_general_ci", limit: 256
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
