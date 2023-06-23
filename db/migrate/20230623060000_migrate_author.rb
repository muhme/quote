class MigrateAuthor < ActiveRecord::Migration[7.0]

  def up
    if Author.any?
      I18n.locale = :de
      Author.find_each do |author|
        # read threee to translate attributes from author and write in StringTranslation
        author.firstname   = author.read_attribute(:firstname)
        author.name        = author.read_attribute(:name)
        author.description = author.read_attribute(:description)
        author.link        = author.read_attribute(:link)
        author.save!
      end
    end

    execute <<-SQL
    ALTER TABLE authors
      DROP COLUMN `firstname`,
      DROP COLUMN `name`,
      DROP COLUMN `description`,
      DROP COLUMN `link`;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

