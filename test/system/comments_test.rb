require "application_system_test_case"

class CommentsCategoriesTest < ApplicationSystemTestCase
  test "comment listing only as admin" do
    check_page page, "/comments", "h1", /Access Denied .* 403/
    do_login
    check_page page, "/comments", "h1", /Access Denied .* 403/
    visit logout_url
    do_login :admin_user, :admin_user_password
    check_page page, "/comments", "h1", "Comments"
    # first page contains only category comments, jump to the last page to see author and quote comments too
    links = all('div.pagination a[href*="/comments?page="]', visible: true)
    # click on the second to last link in the collection (last link is next)
    links[-2].click if links.size > 1
    assert_selector "img[src*='/assets/category']"
    assert_selector "img[src*='/assets/author']"
    assert_selector "img[src*='/assets/zitat-service']"
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
