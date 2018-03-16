require "application_system_test_case"

class StaticPagessTest < ApplicationSystemTestCase

  test "home" do
    check_page page, "/", "h2", "Dankeschön", 1000
    assert_equal page.title, "Zitat-Service"
  end
  
  test "contact" do
    check_page page, "static_pages/contact", "h1", "Impressum", 500
    assert_equal page.title, "Zitat-Service - Impressum"
  end
  
  test "help" do
    check_page page, "static_pages/help", "h1", "Hilfe", 3000
    assert_equal page.title, "Zitat-Service - Hier wird Dir geholfen!"
  end
  
  test "project" do
    check_page page, "static_pages/project", "h1", "Projekt", 1500
    assert_equal page.title, "Zitat-Service - Projekt"
  end
  
  test "use" do
    check_page page, "static_pages/use", "h1", "Zitate einbinden", 3000
      assert_equal page.title, "Zitat-Service - Zitate in die eigene Homepage einbinden"
  end
  
  test "humans" do
    check_page page, "humans.txt", nil, "TEAM", 300
  end
    
  test "joomla" do
    check_page page, "joomla", "h2", "Fehler oder Erweiterungen", 4000
    assert_equal page.title, "Zitat-Service - Zitate mit Joomla! in die eigene Homepage einbinden"
  end
    
  test "joomla_english" do
    check_page page, "static_pages/joomla_english", "h2", "Examples", 2500
    assert_equal page.title, "Zitat-Service - Using quotes with Joomla! for the own homepage"
  end

  test "UTF-8 German Umlaut" do
    check_page page, "static_pages/use", "p", "für", 3000
    check_page page, "static_pages/use", "p", "geöffnet", 3000
    check_page page, "static_pages/use", "p", "Änderung", 3000
  end
  
end
