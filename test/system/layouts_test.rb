require "application_system_test_case"

class LayoutsTest < ApplicationSystemTestCase

  test "favicon" do
    visit root_url
    assert page.source.match '<link rel="icon" type="image/x-icon" href="'
    link = page.source.match /<link rel="icon" type="image\/x-icon" href="(.*)"/
    assert_equal link.length, 2 # matching once?
    assert_match /\/assets\/favicon\-.*/, link[1]
    # TODO get favicon
  end

  test "apple touch icon" do
    visit root_url
    assert page.source.match '<link rel="apple-touch-icon"'
    link = page.source.match /<link rel="apple-touch-icon" type="image\/png" href="(.*)"/
    assert_equal link.length, 2 # matching once?
    assert_match /\/assets\/apple\-touch\-icon\-.*/, link[1]
    # TODO get apple-touch-icon
  end

end
