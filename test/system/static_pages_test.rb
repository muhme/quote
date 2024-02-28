require "application_system_test_case"

class StaticPagessTest < ApplicationSystemTestCase
  test "home" do
    check_page page, root_url, "h2", "Thank You", 1000
    assert_equal "Zitat-Service", page.title
    check_page page, root_url(locale: :de), "h2", "Dankeschön", 1000
    assert_equal "Zitat-Service", page.title
  end

  test "contact" do
    check_page page, start_contact_url, "h1", "Imprint", 500
    assert_equal "Zitat-Service – Imprint", page.title
    check_page page, start_contact_url(locale: :de), "h1", "Impressum", 500
    assert_equal "Zitat-Service – Impressum", page.title
  end

  test "help" do
    check_page page, start_help_url, "h1", "Help", 3000
    assert_equal "Zitat-Service – Don't worry, we're happy to help!", page.title
    check_page page, start_help_url(locale: :de), "h1", "Hilfe", 3000
    assert_equal "Zitat-Service – Keine Sorge, wir helfen Dir gerne weiter!", page.title
  end

  test "project" do
    check_page page, start_project_url, "h1", "Project", 1300
    assert_equal "Zitat-Service – Project", page.title
    check_page page, start_project_url(locale: :de), "h1", "Projekt", 1500
    assert_equal "Zitat-Service – Projekt", page.title
  end

  test "use" do
    check_page page, start_use_url, "h1", "Embedding Quotes", 2000
    assert_equal "Zitat-Service – Embed quotes into your own homepage", page.title
    check_page page, start_use_url(locale: :de), "h1", "Zitate einbinden", 2000
    assert_equal "Zitat-Service – Zitate in die eigene Homepage einbinden", page.title
  end

  test "humans" do
    check_page page, "humans.txt", nil, "TEAM", 300
  end

  test "joomla" do
    # old Joomla plugin update
    visit '/joomla/zitat-service-update.xml'
    check_page_source page, 'updates'

    # redirected URLs
    check_page page, '/joomla', "h1", "Joomla", 4000
    assert_equal page.current_url, QUOTE_JOOMLA_WIKI[:de]

    check_page page, '/joomla_english', "h1", "Joomla", 4000
    assert_equal page.current_url, QUOTE_JOOMLA_WIKI[:en]

    check_page page, '/es/joomla', "h1", "Joomla", 4000
    assert_equal page.current_url, QUOTE_JOOMLA_WIKI[:es]

    # more cases are tested in minitest
  end

  test "UTF-8 German Umlaut" do
    url = start_use_url(locale: :de)
    check_page page, url, "p", "für", 2000
    check_page page, url, "p", "können", 2000
    check_page page, url, "p", "erfährst", 2000
  end

  test "403 forbidden" do
    check_page(page, quotations_list_no_public_url, "div", "Not an Administrator!", 150)
    check_page(page, quotations_list_no_public_url(locale: :de), "div", "Kein Administrator!", 150)
  end
  test "404 not found" do
    ["/bla", "/bla.html", "/bla.png", "/bla.gif", "/bla.css", "/bla.js", "/bla.tiff", "/quotations.jpg",
     "/a/b", "/a/b.html", "/a/b.png", "/a/b.gif", "/a/b.css", "/a/b.js", "/authors/0.jpg", "/quotations/1.json",
     "/categories/1.json"].each { |url|
      check_page(page, url, "h1", /Page not found .* 404/, 150)
    }
  end
  test "422 unprocessable entity" do
    check_page(page, "/422", "h1", /Unprocessable Entity .* 422/, 150)
  end
  test "500 internal server error" do
    check_page(page, "/500", "h1", /Internal Server Error .* 500/, 150)
  end

  test "author link" do
    visit root_url
    check_page_source page, '<link type="text/plain" rel="author" href="/humans.txt">'
  end
end
