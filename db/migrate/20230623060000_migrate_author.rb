class MigrateAuthor < ActiveRecord::Migration[7.0]
  def up
    if Author.any?
      # so far we collected all quotes in :de
      I18n.locale = Mobility.locale = :de
      print("default locale set #{I18n.locale}\n")
      Author.find_each do |author|
        # save author attributes in StringTranslation
        firstname   = author.read_attribute(:firstname)
        name        = author.read_attribute(:name)
        description = author.read_attribute(:description)
        link        = author.read_attribute(:link)
        print("#{author.id};DE;#{firstname};#{name};#{description};#{link}\n")
        # write old as :de with cleaned link
        author.send("firstname_de=", firstname)
        author.send("name_de=", name)
        author.send("description_de=", description)
        author.send("link_de=", WikipediaService.new.clean_link(link))
        # if we have wikipedia link, then find links in other locales and use author name from wikipedia
        WikipediaService.new.ask_wikipedia(:de, author)
        # translate description and name (if not already found on wikipedia)
        if !DeeplService.new.author_translate(:de, author)
          print("\nDeeplService failed for id=#{author.id}\n")
        end
        I18n.available_locales.each do |locale|
          Mobility.with_locale(locale) do
            print("#{author.id};#{locale};#{author.firstname};#{author.name};#{author.description};#{author.link}\n")
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
