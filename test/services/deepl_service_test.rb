require 'test_helper'

class DeeplServiceTest < ActiveSupport::TestCase
  test "method deepl_translate_words" do
    translations = {
        de: 'Berg',
        en: 'Mountain',
        es: 'Montaña',
        ja: '山',
        uk: 'Гора'
      }
    I18n.available_locales.each do |locale|
        translation = DeeplService.new.translate_words("Berg", "de", locale)
        assert_equal translations[locale], translation
    end
  end
  test "should return nil when DeepL API key is missing" do
    saved = ENV["DEEPL_API_KEY"]
    ENV["DEEPL_API_KEY"] = nil
    translation = DeeplService.new.translate_words("Berg", "de", "en")
    assert_nil translation
    # set again for following tests
    ENV["DEEPL_API_KEY"] = saved
  end
  test "should handle DeepL translation failure" do
    translation = DeeplService.new.translate_words("Berg", "XX", "YY")
    assert_nil translation
  end

  # real world sample id 290
  test "author translate" do
    I18n.locale = :de
    author = Author.new
    author.id = 42
    author.user_id = 1
    author.name_de = 'Covington'
    author.firstname_de = 'Michael A.'
    author.description_de = 'US-amerikanischer Professor für Computerwissenschaften'

    # translate
    assert DeeplService.new.author_translate(:de, author)

    # check firstname and name
    [:en, :es].each do |locale|
      assert_equal author.name_de, author.send("name_#{locale}"), "author.name wrong in #{locale}"
      assert_equal author.firstname_de, author.send("firstname_#{locale}"), "author.firstname wrong in #{locale}"
    end
    assert_equal "Ковінгтон" , author.send("name_uk")     , "author.name wrong in :uk"
    assert_equal "Майкл А."  , author.send("firstname_uk"), "author.firstname wrong in :uk"
    assert_equal "コヴィントン", author.send("name_ja")     , "author.name wrong in :ja"
    assert_equal "マイケル・A" , author.send("firstname_ja"), "author.firstname wrong in :ja"

    # check description
    assert_equal "US professor of computer science"        , author.send("description_en"), "author.description wrong in :en"
    assert_equal "Profesor estadounidense de informática"  , author.send("description_es"), "author.description wrong in :es"
    assert_equal "米コンピューターサイエンス教授"               , author.send("description_ja"), "author.description wrong in :ja"
    assert_equal "Американський професор комп'ютерних наук", author.send("description_uk"), "author.description wrong in :uk"
  end
end
