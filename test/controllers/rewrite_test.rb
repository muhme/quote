require "application_system_test_case"

class RewriteTest < ActionDispatch::IntegrationTest
  test "categories_trailing_slash" do
    assert_trailing_slash categories_url
    assert_trailing_slash categories_url + '?page=1'
  end

  test "quotations_trailing_slash" do
    assert_trailing_slash quotations_url
    assert_trailing_slash quotations_url + '?page=2'
  end

  test "authors_trailing_slash" do
    assert_trailing_slash authors_url
    assert_trailing_slash authors_url + '?page=3'
  end

  # test three static pages
  test "static_pages_trailing_slash" do
    assert_trailing_slash "/start/project"
    assert_trailing_slash "/start/help"
    assert_trailing_slash "/humans.txt"
  end
end
