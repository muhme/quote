class MigrateCategory < ActiveRecord::Migration[7.0]

  def up
    if Category.any?
      I18n.locale = :de
      Category.find_each do |category|
        # read category.category and write in StringTranslation
        category.category = category.read_attribute(:category)
        category.save!
      end
    end

    execute <<-SQL
      ALTER TABLE categories DROP COLUMN category;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

