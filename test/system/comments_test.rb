require "application_system_test_case"

class CommentsCategoriesTest < ApplicationSystemTestCase

  test "comment listing only as admin" do
    check_page page, "/comments", "h1", /Access Denied .* 403/
    do_login
    check_page page, "/comments", "h1", /Access Denied .* 403/
    visit logout_url
    do_login :admin_user, :admin_user_password
    check_page page, "/comments", "h1", "Comments"
  end

  test "comments exist" do
    # don't use check_page as the page generation with 1'000 comments takes e.g. 4 seconds on Docker container
    visit category_url(locale: "en", id: (categories :with_1000_comments))
    check_this_page page, "h2", "Comments"
    check_this_page page, "div", "This is comment" 
  end
  
  test "one thousend comments" do
    # don't use check_page as the page generation with 1'000 comments takes e.g. 4 seconds on Docker container
    visit category_url(locale: "en", id: (categories :with_1000_comments))
    check_this_page page, "h2", "Comments"
    check_this_page page, "div", "This is comment" 
  end

end
