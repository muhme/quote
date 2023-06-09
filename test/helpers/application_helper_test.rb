require 'test_helper'
include ERB::Util # for e.g. html_escape

class ApplicationHelperTest < ActionView::TestCase

  # this test is only very basic, for real test it is needed to set controller name and controller action, but even this is useless if controller name or controllers action name is changing, therefore page title is tested in system test
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

  test "lh without link" do
    assert_nil lh("Donald J. Trump")
  end

  test "lh with http link" do
    assert_equal "<a popup=\"true\" href=\"http://www.zitat-service.de\">www.zitat-service.de</a>", lh("http://www.zitat-service.de")
  end

  test "lh with https link" do
    assert_equal "<a popup=\"true\" href=\"https://www.zitat-service.de\">www.zitat-service.de</a>", lh("https://www.zitat-service.de")
  end

  test "link_to_joomla method" do
    assert_equal "<a href=\"/joomla/a.zip\">a.zip</a>", link_to_joomla("a.zip")
  end

  #  "Schiller, Friedrich, deutscher Dichter und Philosoph (1759 - 1805)" with max length 80
  #  or "" for unknown author (id=0) or id isn't set
  test "author selected name" do
    assert_equal author_selected_name(authors(:schiller).id), "Schiller, Friedrich, deutscher Dichter und Philosoph (1759 - 1805)"
    assert_equal author_selected_name(authors(:all_fields_max_sizes).id).length, 80
    assert_equal author_selected_name(authors(:unknown).id), "unknown, Unknown Author with ID 0"
    assert_equal author_selected_name(nil), ""
    assert_equal author_selected_name(authors(:only_name).id), "author with only name field set"
    assert_equal author_selected_name(authors(:only_firstname).id), "author with only firstname field set"
    assert_equal author_selected_name(authors(:only_description).id), "author with only description field set"
    assert_equal author_selected_name(authors(:name_and_firstname).id), "name field, firstname field"
  end

  test "string for locale" do
    assert_match /DE/, string_for_locale
    assert_match /DE/, string_for_locale(nil)
    assert_match /DE/, string_for_locale(nil, true)
    assert_match /DE/, string_for_locale("de")
    assert_match /DE/, string_for_locale("quark cake")
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

end
