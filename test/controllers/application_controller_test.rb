require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @default_headers = {
      "HTTP_ACCEPT_LANGUAGE" => "en",
    }
  end

  # default_url_options()
  test "should set locale from params" do
    get root_url(locale: "en"), headers: @default_headers
    assert_equal "en", I18n.locale.to_s
  end
  test "should set locale from HTTP_ACCEPT_LANGUAGE header" do
    @default_headers["HTTP_ACCEPT_LANGUAGE"] = "ja"
    get root_url, headers: @default_headers
    assert_equal "ja", I18n.locale.to_s
  end
  test "should set default locale" do
    @default_headers["HTTP_ACCEPT_LANGUAGE"] = nil
    get root_url, headers: @default_headers
    assert_equal I18n.default_locale.to_s, I18n.locale.to_s
  end

  # deepl_translate()
  test "should translate text using DeepL" do
    translations = {
        de: 'Berg',
        en: 'Mountain',
        es: 'Montaña',
        ja: '山',
        uk: 'Гора'
      }
    I18n.available_locales.each do |locale|
        translation = ApplicationController.new.deepl_translate("Berg", "de", locale)
        assert_equal translations[locale], translation
    end
  end
  test "should return nil when DeepL API key is missing" do
    ENV["DEEPL_API_KEY"] = nil
    translation = ApplicationController.new.deepl_translate("Berg", "de", "en")
    assert_nil translation
  end
  test "should handle DeepL translation failure" do
    translation = ApplicationController.new.deepl_translate("Berg", "XX", "YY")
    assert_nil translation
  end
end
