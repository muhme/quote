require "test_helper"
include ERB::Util # for e.g. html_escape

class ApplicationHelperTest < ActionView::TestCase
  def setup
  end

  # this test is only very basic, for real test it is needed to set controller name and controller action,
  # but even this is useless if controller name or controllers action name is changing,
  # therefore page title is tested in system test
  test "page_title method" do
    assert_equal "Zitat-Service", page_title
  end

  test "nice_number method" do
    assert_equal "1.234", nice_number(1234)
    assert_equal "0", nice_number(0)
    assert_equal "42", nice_number(42)
    assert_equal "1.004", nice_number(1004)
  end

  test "author_name method simple" do
    assert_equal "James <b>B</b>rown", author_name("James", "Brown")
  end

  test "author_name method without firstname" do
    assert_equal "<b>B</b>rown", author_name("", "Brown")
    assert_equal "<b>B</b>rown", author_name(nil, "Brown")
  end

  test "author_name method with only firstname" do
    assert_equal "James", author_name("James", "")
    assert_equal "James", author_name("James", nil)
  end

  test "author_name method with no name at all" do
    assert_equal "", author_name("", "")
    assert_equal "", author_name(nil, nil)
  end

  test "author_name method with long firstname" do
    assert_equal "XXXXXXXXXXXXXXXXXXXXXX... <b>B</b>rown", author_name("X" * 64, "Brown")
    assert_equal "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ...", author_name("Z" * 64, nil)
  end

  test "author_name method with long last name" do
    assert_equal "James <b>Y</b>YYYYYYYYYYYYYYYYYYYYYYY...", author_name("James", "Y" * 64)
    assert_equal "<b>W</b>WWWWWWWWWWWWWWWWWWWWWWWWWWWWW...", author_name(nil, "W" * 64)
  end

  test "author_name method with long first and last name" do
    assert_equal "AAAAAAAAAAAAAAAAAAAAAA... <b>B</b>BBB...", author_name("A" * 64, "B" * 64)
  end

  test "author_name method with German Umlaut" do
    assert_equal "<b>Ä</b>sop", author_name(nil, "Äsop")
  end

  test "author_name method for japanese" do
    assert_equal "<b>ゲ</b>ーテ・ヨハン・ヴォルフガング・フォン", author_name("ヨハン・ヴォルフガング・フォン", "ゲーテ", :ja)
    assert_equal "<b>不</b>明", author_name(nil, "不明", :ja)
    assert_equal "ボビー, 7年", author_name("ボビー, 7年", nil, :ja)
  end

  test "author_name method for stability" do
    assert_equal "", author_name(nil, nil)
    assert_equal "", author_name("", nil)
    assert_equal "", author_name(nil, "")
    assert_equal "", author_name("", "")
    assert_equal "", author_name(nil, nil, nil)
    assert_equal "", author_name(nil, nil, :XX)
    assert_equal "", author_name(" ", " ")
  end

  test "lh without link" do
    assert_nil lh("Donald J. Trump")
    assert_nil lh("")
    assert_nil lh(nil)
  end

  test "lh with http link" do
    assert_equal "<a popup=\"true\" href=\"http://www.zitat-service.de\">www.zitat-service.de</a>",
                 lh("http://www.zitat-service.de")
  end

  test "lh with https link" do
    assert_equal "<a popup=\"true\" href=\"https://www.zitat-service.de\">www.zitat-service.de</a>",
                 lh("https://www.zitat-service.de")
  end

  test "link_to_joomla method" do
    assert_equal "<a href=\"/joomla/a.zip\">a.zip</a>", link_to_joomla("a.zip")
  end

  test "author selected name" do
    assert_equal "Schiller, Friedrich, German poet and philosopher (1759 - 1805)",
                 author_selected_name(authors(:schiller).id)
    assert_equal "unknown, Unknown Author with ID 0", author_selected_name(authors(:unknown).id)
    assert_equal "", author_selected_name(nil)
    assert_equal "author with only name field set", author_selected_name(authors(:only_name).id)
    assert_equal "author with only firstname field set", author_selected_name(authors(:only_firstname).id)
    assert_equal "author with only description field set", author_selected_name(authors(:only_description).id)
    assert_equal "name field, firstname field", author_selected_name(authors(:name_and_firstname).id)
  end

  test "string for locale" do
    assert_match /EN/, string_for_locale
    assert_match /EN/, string_for_locale(nil)
    assert_match /EN/, string_for_locale(nil, true)
    assert_match /DE/, string_for_locale("de")
    assert_match /EN/, string_for_locale("quark cake")
    assert_match /DE/, string_for_locale("de", true)
    assert_match /DE/, string_for_locale("de", false)
    assert_match /Deutsch/, string_for_locale("de", false)
    refute_match /Deutsch/, string_for_locale("de", true)
    assert_match /EN/, string_for_locale("en", false)
    assert_match /English/, string_for_locale("en", false)
    refute_match /English/, string_for_locale("en", true)
    assert_match /ES/, string_for_locale("es", false)
    assert_match /Español/, string_for_locale("es", false)
    refute_match /Español/, string_for_locale("es", true)
    assert_match /JA/, string_for_locale("ja", false)
    assert_match /日本語/, string_for_locale("ja", false)
    refute_match /日本語/, string_for_locale("ja", true)
    assert_match /UK/, string_for_locale("uk", false)
    assert_match /Українська/, string_for_locale("uk", false)
    refute_match /Українська/, string_for_locale("uk", true)
  end

  test "string for locale only flag" do
    assert_equal '&#x1F1FA;&#x1F1F8;', string_for_locale(nil, nil, true) # 🇺🇸
    assert_equal '&#x1F1FA;&#x1F1F8;', string_for_locale("en", nil, true) # 🇺🇸
    assert_equal '&#x1F1FA;&#x1F1F8;', string_for_locale(:en, nil, true) # 🇺🇸
    assert_equal '&#x1F1E9;&#x1F1EA;', string_for_locale(:de, nil, true) # 🇩🇪
    assert_equal '&#x1F1EA;&#x1F1F8;', string_for_locale(:es, nil, true) # 🇪🇸
    assert_equal '&#x1F1EF;&#x1F1F5;', string_for_locale(:ja, nil, true) # 🇯🇵
    assert_equal '&#x1F1FA;&#x1F1E6;', string_for_locale(:uk, nil, true) # 🇺🇦
  end

  # [:de, :en, :es, :ja, :uk]
  test "next locale" do
    assert_match "de", next_locale
    assert_match "de", next_locale(nil)
    assert_match "de", next_locale(:uk)
    assert_match "de", next_locale("uk")
    assert_match "en", next_locale(:de)
    assert_match "en", next_locale("de")
    assert_match "uk", next_locale(:ja)
    assert_match "uk", next_locale("ja")
  end

  test "transformLink" do
    # rubocop:disable Layout/LineLength
    # real world, from categories/356 and at the end and DE
    assert_match 'im Sinne einer nicht ernst gemeinten Äußerung oder Handlung, die zur Belustigung dienen soll; siehe auch <a href="/de/categories/355" data-turbo="false">Witz</a>',
                 transformLink("im Sinne einer nicht ernst gemeinten Äußerung oder Handlung, die zur Belustigung dienen soll; siehe auch Witz:https://www.zitat-service.de/de/categories/355")
    # in the beginning and EN
    assert_match '<a href="/en/quotations/1902" data-turbo="false">#1902</a> is identical',
                 transformLink("#1902:https://www.zitat-service.de/en/quotations/1902 is identical")
    # only the link and w/o locale
    assert_match '<a href="/authors/20" data-turbo="false">Einstein</a>',
                 transformLink("Einstein:https://www.zitat-service.de/authors/20")
    # two links and in the middle and ES
    assert_match 'ver categorías <a href="/es/categories/305" data-turbo="false">Hormiga</a> y <a href="/es/categories/25" data-turbo="false">Perro</a> ambas recogen animales',
                 transformLink("ver categorías Hormiga:https://www.zitat-service.de/es/categories/305 y Perro:https://www.zitat-service.de/es/categories/25 ambas recogen animales")
    # external links are not transformed
    assert_match "bla https://www.googe.com bli",
                 transformLink("bla https://www.googe.com bli")
    # own links are not transformed and HTML sanitize
    assert_match "&lt;a href=&quot;https://www.google.de&quot;&gt;bla&lt;/a&gt;",
                 transformLink('<a href="https://www.google.de">bla</a>')
    # test tab and JA
    assert_match '名前 <a href="/ja/categories/210" data-turbo="false">はじめに</a>',
                 transformLink("名前\tはじめに:https://www.zitat-service.de/ja/categories/210")
    # test new line and UK and apostroph ' is mapped to &#39; too
    assert_match 'До Основ&#39;яненка Слава <a href="/uk/quotations/1899" data-turbo="false">Україні!</a>',
                 transformLink("До Основ\'яненка\nСлава Україні!:https://www.zitat-service.de/uk/quotations/1899")
  end

  test "ordered locales" do
    default_locales = [:de, :en, :es, :ja, :uk]

    assert_equal [:en, :de, :es, :ja, :uk], ordered_locales(:en)
    assert_equal [:es, :de, :en, :ja, :uk], ordered_locales(:es)
    assert_equal [:ja, :de, :en, :es, :uk], ordered_locales(:ja)
    assert_equal [:uk, :de, :en, :es, :ja], ordered_locales(:uk)
    assert_equal default_locales, ordered_locales(:de)

    # Noting that "fr" is not in the available locales, it should return the original locales
    assert_equal default_locales, ordered_locales(:fr)

    # Testing actual locale
    I18n.locale = :de
    assert_equal default_locales, ordered_locales()
  end
end
