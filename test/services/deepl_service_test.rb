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
end
