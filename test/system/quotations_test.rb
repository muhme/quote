require "application_system_test_case"

class QuotationsTest < ApplicationSystemTestCase

  test "quotations" do
    check_page page, quotations_url, "h1", "Zitat"
    assert_equal page.title, "Zitat-Service - Zitate"
  end

  test "quotations with login" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_this_page page, nil, 'Hallo first_user, schön dass Du da bist.'
    check_page page, quotations_url, "h1", "Zitat"
    assert_equal page.title, "Zitat-Service - Zitate"
  end

  test "list by category w/o login" do
    check_page page, "quotations/list_by_category/" + Category.first.id.to_s, "h1", "Zitate für die Kategorie"
    assert_equal page.title, "Zitat-Service - Zitate zu public_category"
  end
  test "list by category with login" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_this_page page, nil, 'Hallo first_user, schön dass Du da bist.'
    check_page page, "quotations/list_by_category/" + Category.first.id.to_s, "h1", "Zitate für die Kategorie"
  end
  test "failed to list not existing category" do
    check_page page, "quotations/list_by_category/bla", nil, "Kann Kategory .*bla.* nicht finden!"
  end

  test "list by user" do
    check_page page, "quotations/list_by_user/" + User.first.login.to_s, "h1", "Zitate von"
    assert_equal page.title, "Zitat-Service - Zitate des Benutzers first_user"
  end
  
  test "try to list for not existing user" do
    check_page page, "quotations/list_by_user/leon3", nil, "Kann Benutzer .*leon3.* nicht finden!"
  end

  test "list by author" do
    check_page page, "quotations/list_by_author/" + Author.first.id.to_s, "h1", "Zitate für den Autor"
    assert_equal page.title, "Zitat-Service - Zitate von public_author"
  end
  test "failed to list not existing author" do
    check_page page, "quotations/list_by_author/bli", nil, "Kann den Autor .*bli.* nicht finden!"
  end
  
  test "show quote" do
    check_page page, quotation_url(Quotation.find_by_quotation('public_quotation')), "h1", "Zitat"
    assert_equal page.title, "Zitat-Service - Zitat von public_author"
  end

  test "edit own quote" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, edit_quotation_url(1), "h1", "Zitat bearbeiten"
    fill_in 'quotation_source', with: 'jo!'
    click_on 'Speichern'
    check_this_page page, nil, 'Das Zitat wurde aktualisiert.'
    check_page page, quotation_url(1), nil, 'Quelle:[\s]+jo!' 
  end
  test "edit own quote fails" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, edit_quotation_url(1), "h1", "Zitat bearbeiten"
    fill_in 'quotation_quotation', with: 'jo!'
    click_on 'Speichern'
    check_this_page page, nil, 'Das Zitat wurde aktualisiert.'
    check_page page, quotation_url(1), nil, 'Zitat:[\s]+jo!'
    # try to update second quote to exactly the same content as 1st quote
    check_page page, edit_quotation_url(2), "h1", "Zitat bearbeiten"
    fill_in 'quotation_quotation', with: 'jo!'
    click_on 'Speichern'
    check_this_page page, nil, "Quotation has already been taken"
  end

  test "edit someone else quote" do
    visit login_url
    fill_in 'user_session_login', with: 'second_user'
    fill_in 'user_session_password', with: 'second_user_password'
    click_on 'Anmelden'
    check_page page, quotation_url(Quotation.find_by_quotation('public_false')), "h1", "Nicht erlaubt"
  end

  test "try to edit quote from someone else" do
    check_page page, quotation_url(Quotation.find_by_quotation('public_false')), "h1", "Nicht erlaubt"
  end
  
  test "create new quote and delete" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    visit new_quotation_url
    fill_in 'quotation_quotation', with: 'Yes, we can.'
    click_on 'Speichern'
    new_quote = Quotation.last
    check_this_page page, nil, 'Zitat wurde angelegt.'
    check_page page, quotation_url(new_quote), nil, "Öffentlich:[\s]+Nein"
    # delete
    visit quotations_url
    accept_alert do
      find("img[title='Löschen']", match: :first).click
    end
    check_page page, quotation_url(new_quote), "h1", "404 - Nicht gefunden"
  end

  test "failed to save new quote" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    visit new_quotation_url
    fill_in 'quotation_quotation', with: 'Yes, we can.'
    click_on 'Speichern'
    check_this_page page, nil, 'Zitat wurde angelegt.'
    # 2nd try
    visit new_quotation_url
    fill_in 'quotation_quotation', with: 'Yes, we can.'
    click_on 'Speichern'
    check_this_page page, nil, "Quotation has already been taken"
  end

  test "GET creating new quote requires login" do
    check_page page, new_quotation_url, "h1", "Nicht erlaubt"
  end

  test "admin needed to list not public quotes" do
    check_page page, quotations_list_no_public_url, nil, "Kein Administrator!"
  end
  test "list not public quotes" do
    visit login_url
    fill_in 'user_session_login', with: 'admin_user'
    fill_in 'user_session_password', with: 'admin_user_password'
    click_on 'Anmelden'
    check_this_page page, nil, 'Hallo admin_user, schön dass Du da bist.'
    check_page page, quotations_list_no_public_url, "h1", "Nicht-Öffentliche Zitate"
  end

  # NICE cannot delete quote created by another user

end