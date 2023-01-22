require "application_system_test_case"

class QuotationsTest < ApplicationSystemTestCase

  test "quotations" do
    check_page page, quotations_url, "h1", "Zitat"
    assert_equal page.title, "Zitat-Service - Zitate"
  end

  test "quotations with login" do
    do_login
    check_this_page page, nil, 'Hallo first_user, schön dass Du da bist.'
    check_page page, quotations_url, "h1", "Zitat"
    assert_equal page.title, "Zitat-Service - Zitate"
  end

  test "list by category w/o login" do
    check_page page, "quotations/list_by_category/" + Category.first.id.to_s, "h1", "Zitate für die Kategorie"
    assert_equal page.title, "Zitat-Service - Zitate zu public_category"
  end
  test "list by category with login" do
    do_login
    check_this_page page, nil, 'Hallo first_user, schön dass Du da bist.'
    check_page page, "quotations/list_by_category/" + Category.first.id.to_s, "h1", "Zitate für die Kategorie"
  end
  test "failed to list not existing category" do
    check_page page, "quotations/list_by_category/bla", nil, /Kann Kategory .*bla.* nicht finden!/
  end

  test "list by user" do
    check_page page, "quotations/list_by_user/" + User.first.login.to_s, "h1", "Zitate von"
    assert_equal page.title, "Zitat-Service - Zitate des Benutzers first_user"
  end
  
  test "try to list for not existing user" do
    check_page page, "quotations/list_by_user/leon3", nil, /Kann Benutzer .*leon3.* nicht finden!/
  end

  test "list by author" do
    check_page page, "quotations/list_by_author/#{authors(:schiller).id}", "h1", /Zitate für den Autor.*Friedrich Schiller/
    assert_equal page.title, "Zitat-Service - Zitate von Friedrich Schiller"
  end
  test "failed to list not existing author" do
    check_page page, "quotations/list_by_author/bli", nil, /Kann den Autor .*bli.* nicht finden!/
  end
  
  test "show quote" do
    check_page page, quotation_url(1), "h1", "Zitat"
    assert_equal page.title, "Zitat-Service - Zitat von Barbara"
  end

  # linking author's name with that author's quotes #13
  test "multiple quotes with author link" do
    # quote #1 is from author #1 which has multiple quotes
    check_page page, "quotations/1", "h1", "Zitat"
    check_page_source page, /href="\/quotations\/list_by_author\//
  end
  test "single quote with author link" do
    # quote #3 is from author #2 which has only one single quote
    check_page page, "quotations/3", "h1", "Zitat"
    check_page_source page, /href="\/quotations\/list_by_author\//
  end
  # same for user, has to be linked if at least one user exists
  test "multiple quotes with user link" do
    # quote #1 is from user #1 which has multiple quotes
    check_page page, "quotations/1", "h1", "Zitat"
    check_page_source page, /href="\/quotations\/list_by_user\//
  end
  test "single quote with user link" do
    # quote #3 is from author #2 which has only one single quote
    check_page page, "quotations/3", "h1", "Zitat"
    check_page_source page, /href="\/quotations\/list_by_user\//
  end

  test "edit own quote" do
    do_login
    check_page page, edit_quotation_url(1), "h1", "Zitat bearbeiten"
    fill_in 'quotation_source', with: 'jo!'
    fill_in 'search_author_author', with: 'schiller'
    check_this_page page, nil, "Schiller, Friedrich" # wait for turbo
    click_on 'Speichern'
    check_this_page page, nil, 'Das Zitat wurde aktualisiert.'
    check_page page, quotation_url(1), nil, /Quelle:.*jo!/
    check_this_page page, nil, /Autor:.*Friedrich Schiller/
  end
  test "edit own quote fails" do
    do_login
    check_page page, edit_quotation_url(1), "h1", "Zitat bearbeiten"
    fill_in 'quotation_quotation', with: 'jo!'
    click_on 'Speichern'
    check_this_page page, nil, 'Das Zitat wurde aktualisiert.'
    check_page page, quotation_url(1), nil, /Zitat:.*jo!/
    # try to update second quote to exactly the same content as 1st quote
    check_page page, edit_quotation_url(2), "h1", "Zitat bearbeiten"
    fill_in 'quotation_quotation', with: 'jo!'
    click_on 'Speichern'
    check_this_page page, nil, "Quotation has already been taken"
  end

  test "author autocompletion select one in the list" do
    do_login
    check_page page, edit_quotation_url(1), "h1", "Zitat bearbeiten"
    fill_in 'search_author_author', with: 'Eva'
    click_on 'Eva 10'
    click_on 'Speichern'
    check_this_page page, nil, 'Das Zitat wurde aktualisiert.'
    check_this_page page, nil, /Autor:.*Eva 10/
  end
  test "author autocompletion give name" do
    do_login
    check_page page, edit_quotation_url(1), "h1", "Zitat bearbeiten"
    fill_in 'search_author_author', with: 'Eva 19'
    check_this_page page, nil, /Eva 19,/ # wait until autor found
    click_on 'Speichern'
    check_this_page page, nil, 'Das Zitat wurde aktualisiert.'
    check_this_page page, nil, /Autor:.*Eva 19/
  end
  test "author autocompletion multiple authors" do
    do_login
    check_page page, edit_quotation_url(1), "h1", "Zitat bearbeiten"
    fill_in 'search_author_author', with: 'Eva'
    click_on 'Speichern'
    check_this_page page, nil, 'Das Zitat wurde aktualisiert.'
    check_this_page page, nil, /Autor:.*unknown/
  end
  test "author autocompletion not existing author" do
    do_login
    check_page page, edit_quotation_url(1), "h1", "Zitat bearbeiten"
    fill_in 'search_author_author', with: 'brabbel zabbel'
    click_on 'Speichern'
    check_this_page page, nil, 'Das Zitat wurde aktualisiert.'
    check_this_page page, nil, /Autor:.*unknown/
  end
  test "author autocompletion change quote" do
    do_login
    check_page page, edit_quotation_url(1), "h1", "Zitat bearbeiten"
    fill_in 'search_author_author', with: 'Schiller'
    fill_in 'quotation_quotation', with: 'Wer sich über die Wirklichkeit nicht hinauswagt, der wird nie die Wahrheit erobern.'
    click_on 'Speichern'
    check_this_page page, nil, 'Zitat wurde aktualisiert.'
    check_page page, quotation_url(1), nil, /Zitat:.*Wer sich über die Wirklichkeit nicht hinauswagt, der wird nie die Wahrheit erobern./
    check_this_page page, nil, /Autor:.*Friedrich Schiller/
    # existing author is not changed
    check_page page, edit_quotation_url(1), "h1", "Zitat bearbeiten"
    fill_in 'quotation_quotation', with: 'der zankapfel schmeckt bitter'
    click_on 'Speichern'
    check_this_page page, nil, 'Zitat wurde aktualisiert.'
    check_page page, quotation_url(1), nil, /Zitat:.*der zankapfel schmeckt bitter/
    check_this_page page, nil, /Autor:.*Friedrich Schiller/
    # autocomplete gives a list > 1
    check_page page, edit_quotation_url(1), "h1", "Zitat bearbeiten"
    fill_in 'quotation_quotation', with: 'Hardware eventually fails. Software eventually works.'
    fill_in 'search_author_author', with: 'Eva'
    click_on 'Speichern'
    check_page page, quotation_url(1), nil, /Zitat:.*Hardware eventually fails. Software eventually works./
    check_this_page page, nil, /Autor:.*unknown/
  end
  test "author autocompletion create quote" do
    do_login
    visit new_quotation_url
    fill_in 'search_author_author', with: 'Schiller'
    fill_in 'quotation_quotation', with: 'Die Sterne lügen nicht.'
    click_on 'Speichern'
    check_this_page page, nil, 'Zitat wurde angelegt.'
    new_quote = Quotation.last
    check_page page, quotation_url(new_quote), nil, /Zitat:.*Die Sterne lügen nicht./
    check_this_page page, nil, /Autor:.*Friedrich Schiller/
    # check session variable author_id is eaten
    visit new_quotation_url
    fill_in 'quotation_quotation', with: 'Die Axt im Haus erspart den Zimmermann.'
    click_on 'Speichern'
    check_this_page page, nil, 'Zitat wurde angelegt.'
    new_quote = Quotation.last
    check_page page, quotation_url(new_quote), nil, /Zitat:.*Die Axt im Haus erspart den Zimmermann./
    check_this_page page, nil, /Autor:.*unknown/
  end
  test "author autocompletion edit second quote bug #57" do
    do_login
    check_page page, edit_quotation_url(1), "h1", "Zitat bearbeiten" # 1st quote has author id 1 "Barbara"
    check_page_source page, /Barbara/ # is given in HTML form as input value, therefore to user check_page_source
    check_page page, edit_quotation_url(2), "h1", "Zitat bearbeiten" # 2nd quote has author id 2 "second author"
    check_page_source  page, /second author/
    click_on 'Speichern'
    check_this_page page, nil, 'Zitat wurde aktualisiert.'
    check_this_page page, nil, /Autor:.*second author.*/
  end

  test "edit someone else quote" do
    do_login :second_user, :second_user_password
    check_page page, quotation_url(Quotation.find_by_quotation('public_false')), "h1", /Zugriff wurde verweigert .* 403/
  end

  test "try to edit quote from someone else" do
    check_page page, quotation_url(Quotation.find_by_quotation('public_false')), "h1", /Zugriff wurde verweigert .* 403/
  end
  
  test "create new quote and delete" do
    do_login
    visit new_quotation_url
    fill_in 'quotation_quotation', with: 'Yes, we can.'
    click_on 'Speichern'
    check_this_page page, nil, 'Zitat wurde angelegt.'
    new_quote = Quotation.last
    check_page page, quotation_url(new_quote), nil, /Öffentlich:.*Nein/
    # delete
    visit quotations_url
    accept_alert do
      find("img[title='Löschen']", match: :first).click
    end
    check_page page, quotation_url(new_quote), "h1", /Seite nicht gefunden .* 404/
  end

  test "failed to save new quote" do
    do_login
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
    check_page page, new_quotation_url, "h1", /Zugriff wurde verweigert .* 403/
  end

  test "admin needed to list not public quotes" do
    check_page page, quotations_list_no_public_url, nil, "Kein Administrator!"
  end
  test "list not public quotes" do
    do_login :admin_user, :admin_user_password
    check_this_page page, nil, 'Hallo admin_user, schön dass Du da bist.'
    check_page page, quotations_list_no_public_url, "h1", "Nicht-Öffentliche Zitate"
  end

  test "trailing slash" do
    check_page page, quotations_url + '/', "h1", "Zitat"
    assert_equal page.title, "Zitat-Service - Zitate"
    # redirected URL w/o slash
    assert_equal page.current_url, quotations_url
  end

  test "pagination with trailing slash" do
    url = quotations_url + '?page=2/'
    check_page page, url, "h1", "Zitat"
    check_this_page page, nil, "Aktionen"
    # redirected URL w/o slash
    assert_equal page.current_url, url.chop
  end

  test "pagination not found" do
    url = quotations_url + '?page=420000'
    check_page page, url, "h1", /Seite nicht gefunden.*404/
    # wrong URL have to be shown
    check_this_page page, nil, url
    check_page_source page, /href=".*quote\/issues/
  end

  # NICE cannot delete quote created by another user

end
