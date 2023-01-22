require "application_system_test_case"

class StaticPagessTest < ApplicationSystemTestCase

  test "home" do
    check_page page, "/", "h2", "Dankeschön", 1000
    assert_equal page.title, "Zitat-Service"
  end
  
  test "contact" do
    check_page page, "start/contact", "h1", "Impressum", 500
    assert_equal page.title, "Zitat-Service - Impressum"
  end
  
  test "help" do
    check_page page, "start/help", "h1", "Hilfe", 3000
    assert_equal page.title, "Zitat-Service - Hier wird Dir geholfen!"
  end
  
  test "project" do
    check_page page, "start/project", "h1", "Projekt", 1500
    assert_equal page.title, "Zitat-Service - Projekt"
  end
  
  test "use" do
    check_page page, "start/use", "h1", "Zitate einbinden", 3000
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
    check_page page, "start/joomla_english", "h2", "Examples", 2500
    assert_equal page.title, "Zitat-Service - Using quotes with Joomla! for the own homepage"
  end

  test "direct route joomla_english" do
    check_page page, "joomla_english", "h2", "Examples", 2500
    assert_equal page.title, "Zitat-Service - Using quotes with Joomla! for the own homepage"
  end

  test "UTF-8 German Umlaut" do
    check_page page, "start/use", "p", "für", 3000
    check_page page, "start/use", "p", "geöffnet", 3000
    check_page page, "start/use", "p", "Änderung", 3000
  end
  
  test "403 forbidden" do
      check_page(page, "/quotations/list_no_public", "div", "Kein Administrator!", 150)
  end
  test "404 not found" do
    ["/bla", "/bla.html", "/bla.png", "/bla.gif", "/bla.css", "/bla.js", "/bla.tiff", "/quotations.jpg",
     "/a/b", "/a/b.html", "/a/b.png", "/a/b.gif", "/a/b.css", "/a/b.js", "/authors/0.jpg", "/quotations/1.json", "/categories/1.json"
    ].each {
      |url| check_page(page, url, "h1", /Seite nicht gefunden .* 404/, 150)
    }
  end
  test "422 unprocessable entity" do
    check_page(page, "/422", "h1", "HTTP-Statuscode 422", 150)
  end
  test "500 internal server error" do
    check_page(page, "/500", "h1", "HTTP-Statuscode 500", 150)
  end
  
  test "HTML lang" do
    [root_url, joomla_url, authors_url, author_url(Author.find_by_name('Barbara'))].each {
      |url|
        visit url
        assert page.source.match('<html lang="de">')
    }
    visit start_joomla_english_url
    assert page.source.match('<html lang="en">')
  end
  
end
