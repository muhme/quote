class MigrateAuthor < ActiveRecord::Migration[7.0]
  def up
    if Author.any?
      Author.find_each do |author|
        # save author attributes in StringTranslation
        firstname   = author.read_attribute(:firstname)
        name        = author.read_attribute(:name)
        description = author.read_attribute(:description)
        link        = author.read_attribute(:link)
        I18n.available_locales.each do |locale|
          Mobility.with_locale(locale) do
            author.firstname   = firstname
            author.name        = name
            author.description = description
            author.link        = link
          end
        end
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
