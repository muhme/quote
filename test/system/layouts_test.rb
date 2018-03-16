require "application_system_test_case"

class LayoutsTest < ApplicationSystemTestCase

  test "favicon" do
    visit root_url
    page.body.include? '<link rel="icon" type="image/x-icon" href='
    # NICE to improve with something more intelligent, like the following line, but this one is not working
    # page.has_xpath?("/html/head/link[@href='favicon.ico']", visible: false) 
  end
  
end
