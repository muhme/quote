class TranslateCategory < ActiveRecord::Migration[7.0]
  require 'deepl'

  if ENV["DEEPL_API_KEY"].blank?
    raise "environment var DEEPL_API_KEY is missing"
  end

  def up
    if Category.any?
      I18n.locale = :de
      locales_without_de = I18n.available_locales.reject { |locale| locale == :de }
      Category.find_each do |category|
        print "#{category.id},#{category.category},"
        locales_without_de.each do |locale|
          I18n.with_locale(locale.to_s) do
            translated = myDeepl_translate(category.category(locale: :de), :de, locale)
            print translated + ","
            category.category = translated
          end
        end
        category.save!
        print "\n"
      end
    end

  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  # copy from application_controller.rb
  # returns translated string and can throw DeepL::Exception
  def myDeepl_translate(text, source_lang, target_lang)
    begin
      source = source_lang.to_s.upcase
      target = target_lang.to_s.upcase
      ret = DeepL.translate(text, source, target).to_s
      ret.chomp!(".") # Українська translation has often a dot in the end
      ret.sub!(/"/, "") # Українська translation has sometimes double quote in the beginning
      ret.sub!(/。/, "") # one time seen, 日本語 translation added japanese dot in the end
      # puts "translate #{source} \”#{text}\" -> #{target} \"#{ret}\""
      return ret
    rescue DeepL::Exceptions::Error => exc
      puts "DeepL translation failed #{exc.class} #{exc.message}"
    end
    return nil
  end

end

