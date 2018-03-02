require "application_system_test_case"

class StaticPagessTest < ApplicationSystemTestCase

  test "home" do
    check_page page, "/", "h2", "Dankeschön", 1000
  end
  
  test "contact" do
    check_page page, "static_pages/contact", "h1", "Impressum", 500
  end
  
  test "help" do
    check_page page, "static_pages/help", "h1", "Hilfe", 3000
  end
  
  test "project" do
    check_page page, "static_pages/project", "h1", "Projekt", 1500
  end
  
  test "use" do
    check_page page, "static_pages/use", "h1", "Zitate einbinden", 3000
  end
  
  test "humans" do
    check_page page, "humans.txt", nil, "TEAM", 300
  end
    
  test "joomla" do
    check_page page, "joomla", "h2", "Fehler oder Erweiterungen", 4000
  end
    
  test "joomla_english" do
    check_page page, "static_pages/joomla_english", "h2", "Examples", 2500
  end

  test "UTF-8 German Umlaut" do
    check_page page, "static_pages/use", "p", "für", 3000
    check_page page, "static_pages/use", "p", "geöffnet", 3000
    check_page page, "static_pages/use", "p", "Änderung", 3000
  end
  
end
