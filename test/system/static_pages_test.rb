require "application_system_test_case"

class StaticPagessTest < ApplicationSystemTestCase
  # test "visiting the index" do
  #   visit static_pagess_url
  #
  #   assert_selector "h1", text: "Start"
  # end
  
  def check_page page, path, selector, content, size
    visit path
    if (defined?(selector)).nil? 
      assert_selector selector, text: content
    else
      assert page.text.include?(content), "page \"#{path}\" is missing text \"#{content}\""
    end
    assert page.text.length >= size, "page \"#{path}\" is with #{page.text.length.to_s} smaller than #{size.to_s}"
  end
  
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
    check_page page, "humans.txt", nil, "TEAM", 3 # TODO
  end
    
  test "joomla" do
    check_page page, "joomla", "h2", "Fehler oder Erweiterungen", 4000
  end
    
  test "joomla_english" do
    check_page page, "static_pages/joomla_english", "h2", "Examples", 2500
  end
  
end
