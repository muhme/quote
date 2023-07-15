# test/services/wiki_service_test.rb

require 'test_helper'

class WikipediaServiceTest < ActiveSupport::TestCase
  LINKS = {
    :de => 'https://de.wikipedia.org/wiki/Karl_Ove_Knausgård',
    :en => 'https://en.wikipedia.org/wiki/Karl_Ove_Knausgård',
    :es => 'https://es.wikipedia.org/wiki/Karl_Ove_Knausgård',
    :ja => 'https://ja.wikipedia.org/wiki/カール・オーヴェ・クナウスゴール',
    :uk => 'https://uk.wikipedia.org/wiki/Карл_Уве_Кнеусгор'
  }.freeze
  NAMES = {
    :de => 'Karl Ove Knausgård',
    :en => 'Karl Ove Knausgård',
    :es => 'Karl Ove Knausgård',
    :ja => 'カール・オーヴェ・クナウスゴール',
    :uk => 'Карл Уве Кнеусгор'
  }.freeze

  def setup
  end

  # for every locale get all other locale links
  test "updates author's link for each locale" do
    LINKS.keys.each do |locale|
      Rails.logger.debug "WikiServiceTest STARTING #{locale}"
      result = WikipediaService.new.call(locale, LINKS[locale])
      links = result[:links]
      names = result[:names]
      Rails.logger.debug "FOUND #{links.inspect}"
      LINKS.each do |locale_check, expected_link|
        if locale_check != locale
          assert_equal expected_link, links[locale_check.to_s],
                       "author link from #{locale} created for #{locale_check} doesn't match"
        end
      end
      NAMES.each do |locale_check, expected_name|
        if locale_check != locale
          assert_equal expected_name, names[locale_check.to_s],
                       "author name from #{locale} created for #{locale_check} doesn't match"
        end
      end
    end
  end
end
