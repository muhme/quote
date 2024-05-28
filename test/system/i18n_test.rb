require "application_system_test_case"

class I18nTest < ApplicationSystemTestCase
  # without language (locale) click on quotes menu entry, wait the quotes page is loaded and check h1 and url
  test "home without language" do
    check_page page, "/", "h1", "Welcome to the quote service zitat-service.de"
    click_on I18n.t("g.quotes", locale: I18n.default_locale, count: 0)
    # first find h1 to wait until the page is loaded ...
    find("h1", text: I18n.t("g.quotes", locale: I18n.default_locale, count: 2))
    # ... and second check url
    assert_equal quotations_url(locale: I18n.default_locale), current_url
  end

  # select a language (locale) and click on quotes menu entry, wait the quotes page is loaded and check h1 and url
  test "select language" do
    I18n.available_locales.each do |locale|
      visit root_url
      find("#current-language").click
      # look and click for unique e.g. data-locale="de"
      find(".language-option[data-locale=\"#{locale}\"]").click
      # click on quotes menu entry
      click_on I18n.t("g.quotes", locale: locale, count: 0)
      # have to unselect actual locale to see all quotes and to find plural title
      uncheck "locale_#{locale}"
      # first find h1 to wait until the page is loaded ...
      # for українська differs it ends in 4 or 5
      find("h1", text: I18n.t("g.quotes", locale: locale, count: Quotation.count))
      # ... and second check url
      assert_equal quotations_url(locale: locale) + "?locales=", current_url
    end
  end

  # check html lang w/o locale and for all locales
  test "html lang" do
    visit root_url
    check_page_source page, "<html lang=\"#{I18n.default_locale.to_s}\">"
    I18n.available_locales.each do |locale|
      visit root_url(locale: locale)
      check_page_source page, "<html lang=\"#{locale.to_s}\">"
    end
  end

  test "check all pages for missing translation" do
    paths = (Rails.application.routes.routes.map do |route|
      verb = route.verb.to_s
      path = route.path.spec.to_s
      # select paths starting with the locale pattern and are not POST requests
      path if path.starts_with?("(/:locale)/") && !verb.include?("POST")
    end.compact)
    # "(/:locale)/authors/new(.:format)",
    # "(/:locale)/authors/:id/edit(.:format)",
    # ...
    all_paths_to_check = []
    paths.each do |path|
      path_wo_format_and_ids = path.gsub(/\(\.:format\)/, "").gsub(/:id/, "1")
      path_wo_format_and_ids = path_wo_format_and_ids.gsub(/:id/, "1")
      path_wo_format_and_ids = path_wo_format_and_ids.gsub(/:ids/, "1,2,3")
      path_wo_format_and_ids = path_wo_format_and_ids.gsub(/:author/, "1")
      path_wo_format_and_ids = path_wo_format_and_ids.gsub(/:author_id/, "1")
      path_wo_format_and_ids = path_wo_format_and_ids.gsub(/:category/, "1")
      path_wo_format_and_ids = path_wo_format_and_ids.gsub(/:letter/, "T")
      path_wo_format_and_ids = path_wo_format_and_ids.gsub(/:user/, "first_user")

      all_paths_to_check << path_wo_format_and_ids.sub(/\(\/:locale\)/, "") # add w/o locale
      I18n.available_locales.each do |locale|
        # add with each locale available
        all_paths_to_check << path_wo_format_and_ids.sub(/\(\/:locale\)/, "/#{locale.to_s}")
      end
    end
    # w/o login
    all_paths_to_check.each do |path|
      visit path
      # Check if the page does not contain an element with the 'translation_missing' class
      assert has_no_css?(".translation_missing"), "Found #{path} with translation missing"
    end
    # w/ login
    do_login
    all_paths_to_check.each do |path|
      visit path
      assert has_no_css?(".translation_missing"), "Found #{path} with translation missing"
    end
  end

  test "set locale" do
    # try home, one static page, one list page, and one item page
    ["/", "start/help", "authors", "quotations/1"].each do |url|
      # w/o any locale set
      visit url
      check_page_source page, "<html lang=\"#{I18n.default_locale.to_s}\">"
      # w/ locale from browser
      # TODO needs some magic or another driver as cypyabara/selenium/chrome to set locale in headless chrome
      # I18n.available_locales.each do |locale|
      [:en].each do |locale|
        visit url
        check_page_source page, "<html lang=\"#{locale.to_s}\">"
      end
      # w/ locale already set and ignore browser
      I18n.available_locales.each do |locale|
        visit "#{locale.to_s}/#{url}"
        check_page_source page, "<html lang=\"#{locale.to_s}\">"
      end
    end
  end
end
