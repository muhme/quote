require "application_system_test_case"

class CommentsCategoriesTest < ApplicationSystemTestCase
  
  test "show existing comment" do
    check_page page, category_url(locale: "en", id: categories(:with_one_comment)), "h1", "Category"
    check_this_page page, "h2", "Comments"
    check_this_page page, "p", "Log in with Login to add comments here."
    # user, created and updated
    check_this_page page, nil, /second_user.*commented on 01.05.2023.*updated on 10.05.2023/
    # comment itself
    check_this_page page, nil, "comment in українська for category \"with_one_comment\""
    # locale
    check_this_page page, "span.flags", "UK"
  end

  test "add new comment" do
    do_login :second_user, :second_user_password
    check_page page, category_url(locale: "en", id: categories(:with_one_comment)), "h1", "Category"
    fill_in "comment_comment", with: "Test Comment"
    click_on "Add"
    check_this_page page, nil, "Test Comment"
    check_this_page page, "span.flags", "EN"
    # reload category
    check_page page, category_url(locale: "en", id: categories(:with_one_comment)), "h1", "Category"
    check_this_page page, nil, "Test Comment"
    check_this_page page, "span.flags", "EN"
  end

  test "no empty comments allowed" do
    do_login :second_user, :second_user_password
    check_page page, category_url(locale: "en", id: categories(:with_one_comment)), "h1", "Category"
    fill_in "comment_comment", with: ""
    click_on "Add"
    check_this_page page, "h2", "Error"
    check_this_page page, nil, "Comment can't be blank"
  end

  test "edit comment and language as own user" do
    do_login :second_user, :second_user_password
    check_page page, category_url(locale: "de", id: categories(:with_one_comment)), "h1", "Kategorie" # Category
    click_on "Stift" # pencil
    fill_in "edit_comment", with: "überschrieben" # overwritten
    click_on "Ändern" # Change
    check_this_page page, nil, "überschrieben"
    # reload category
    check_page page, category_url(locale: "en", id: categories(:with_one_comment)), "h1", "Category"
    check_this_page page, nil, "überschrieben"
    check_this_page page, "span.flags", "DE"
  end

  test "edit comment as admin" do
    do_login :admin_user, :admin_user_password
    check_page page, category_url(locale: "uk", id: categories(:with_one_comment)), "h1", "Категорія" # Category
    page.find('img.edit_comment').click # as admin there are to pencil buttons, one for editing category and one for editing comment
    fill_in "edit_comment", with: "Слава Україні!" # Glory to Ukraine!
    click_on "Змінити" # Change
    check_this_page page, nil, "Слава Україні!"
    # reload category
    check_page page, category_url(locale: "en", id: categories(:with_one_comment)), "h1", "Category"
    check_this_page page, nil, "Слава Україні!"
    check_this_page page, "span.flags", "UK"
  end

  test "not allowed to edit someone else comment" do
    do_login
    check_page page, category_url(locale: "es", id: categories(:with_one_comment)), "h1", "Categoría" # Category
    assert_no_selector('img[class="edit_comment"]')
    visit logout_url
    do_login :second_user, :second_user_password
    check_page page, category_url(locale: "es", id: categories(:with_one_comment)), "h1", "Categoría"
    assert_selector('img[class="edit_comment"]')
  end

  test "delete comment" do
    old_comment = "comment in українська for category \"with_one_comment\""
    do_login :second_user, :second_user_password
    check_page page, category_url(locale: "ja", id: categories(:with_one_comment)), "h1", "カテゴリ" # Category
    assert false, "missing #{old_comment}" unless page.has_text?(old_comment)
    accept_alert do
      find("img[title='削除']").click
    end
    assert false, "still exists #{old_comment}" unless page.has_no_text?(old_comment)
  end

end
