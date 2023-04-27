require "application_system_test_case"

class QuotationsTest < ApplicationSystemTestCase
  test "quotations" do
    check_page page, quotations_url, "h1", "Zitat"
    assert_equal "Zitat-Service – Zitate", page.title
  end

  test "quotations with login" do
    do_login
    check_this_page page, nil, "Hallo first_user, schön dass Du da bist."
    check_page page, quotations_url, "h1", "Zitat"
    assert_equal "Zitat-Service – Zitate", page.title
  end

  test "list by category w/o login" do
    check_page page, "quotations/list_by_category/" + Category.first.id.to_s, "h1", "1 Zitat für die Kategorie public_category"
    assert_equal "Zitat-Service – Zitate zu public_category", page.title
  end
  test "list by category with login" do
    do_login
    check_this_page page, nil, "Hallo first_user, schön dass Du da bist."
    check_page page, "quotations/list_by_category/" + Category.first.id.to_s, "h1", "1 Zitat für die Kategorie public_category"
  end
  test "failed to list not existing category" do
    check_page page, "quotations/list_by_category/bla", nil, /Kann keine Kategorie mit der ID.*bla.* finden!/
  end

  test "list by user" do
    check_page page, "quotations/list_by_user/" + User.first.login.to_s, "h1", "0 Zitate des Benutzers first_user"
    assert_equal "Zitat-Service – Zitate des Benutzers first_user", page.title
  end

  test "try to list for not existing user" do
    check_page page, "quotations/list_by_user/leon3", nil, /Kann keinen Benutzer .*leon3.* finden!/
  end

  test "list by author" do
    check_page page, "quotations/list_by_author/#{authors(:schiller).id}", "h1", /0 Zitate von Friedrich Schiller/
    assert_equal "Zitat-Service – Zitate von Friedrich Schiller", page.title
  end
  test "failed to list not existing author" do
    check_page page, "quotations/list_by_author/bli", nil, /Kann keinen Autor mit der ID.*bli.* finden!/
  end

  test "show quote" do
    check_page page, quotation_url(id: 1), "h1", "Zitat"
    assert_equal "Zitat-Service – Zitat von Barbara", page.title
  end

  # linking author's name with that author's quotes #13
  # linking author from quote #58
  test "multiple quotes with author link" do
    # quote #1 is from author #1 which has multiple quotes
    check_page page, "quotations/1", "h1", "Zitat"
    check_page_source page, /href=".*\/quotations\/list_by_author\//
    check_this_page page, nil, /Autor:.*Zitate\)/
  end
  test "single quote with author link" do
    # quote #3 is from third author which has only one single quote
    check_page page, "quotations/3", "h1", "Zitat"
    assert false, "page \"#{page.current_url}\" shows authors quotes" if page.has_text? "Zitate)"
    assert false, "page \"#{page.current_url}\" shows authors quotes" if page.has_text? "Zitat)"
  end
  # same for user, has to be linked if at least one user exists
  test "multiple quotes with user link" do
    # quote #1 is from user #1 which has multiple quotes
    check_page page, "quotations/1", "h1", "Zitat"
    check_page_source page, /href=".*\/quotations\/list_by_user\//
  end
  test "single quote with user link" do
    # quote #3 is from author #2 which has only one single quote
    check_page page, "quotations/3", "h1", "Zitat"
    check_page_source page, /href=".*\/quotations\/list_by_user\//
  end

  test "edit own quote" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "author", with: "schiller"
    fill_in "quotation_source", with: "jo!"
    assert page.has_css?(".animated") # wait for autocompletion
    click_on "Speichern"
    check_this_page page, nil, "Das Zitat wurde aktualisiert."
    check_page page, quotation_url(id: 1), nil, /Quelle:.*jo!/
    check_this_page page, nil, /Autor:.*Friedrich Schiller/
  end
  test "edit own quote fails" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "quotation_quotation", with: "jo!"
    click_on "Speichern"
    check_this_page page, nil, "Das Zitat wurde aktualisiert."
    check_page page, quotation_url(id: 1), nil, /Zitat:.*jo!/
    # try to update second quote to exactly the same content as 1st quote
    check_page page, edit_quotation_url(id: 2), "h1", "Zitat bearbeiten"
    fill_in "quotation_quotation", with: "jo!"
    click_on "Speichern"
    check_this_page page, nil, "dieses Zitat gibt es bereits"
  end

  test "author autocompletion select one in the list" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "author", with: "Eva"
    click_on "Eva 10"
    click_on "Speichern"
    check_this_page page, nil, "Das Zitat wurde aktualisiert."
    check_this_page page, nil, /Autor:.*Eva 10/
  end
  test "author autocompletion give name" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "author", with: "Eva 1"
    check_this_page page, "div#authors_list", /Eva 1/
    fill_in "author", with: "Eva 19"
    assert page.has_css?(".animated") # wait for autocompletion
    check_page_source page, 'value="Eva 19"'
    click_on "Speichern"
    check_this_page page, nil, "Das Zitat wurde aktualisiert."
    check_this_page page, nil, /Autor:.*Eva 19/
  end
  test "author autocompletion multiple authors" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "author", with: "Eva"
    click_on "Speichern"
    check_this_page page, nil, /Das Zitat wurde nicht geändert. Der Autor .* wurde nicht geändert./
    check_this_page page, nil, /Autor:.*Barbara/
  end
  test "author autocompletion not existing author" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "author", with: "brabbel zabbel"
    click_on "Speichern"
    check_this_page page, nil, /Das Zitat wurde nicht geändert. Der Autor .* wurde nicht geändert./
    check_this_page page, nil, /Autor:.*Barbara/
  end
  test "author autocompletion change quote" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "author", with: "Schiller"
    assert page.has_css?(".animated") # wait for autocompletion
    fill_in "quotation_quotation", with: "Wer sich über die Wirklichkeit nicht hinauswagt, der wird nie die Wahrheit erobern."
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde aktualisiert."
    check_page page, quotation_url(id: 1), nil, /Zitat:.*Wer sich über die Wirklichkeit nicht hinauswagt, der wird nie die Wahrheit erobern./
    check_this_page page, nil, /Autor:.*Friedrich Schiller/
    # existing author is not changed
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "quotation_quotation", with: "der zankapfel schmeckt bitter"
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde aktualisiert."
    check_page page, quotation_url(id: 1), nil, /Zitat:.*der zankapfel schmeckt bitter/
    check_this_page page, nil, /Autor:.*Friedrich Schiller/
    # autocomplete with list > 1 doesn't change author
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "quotation_quotation", with: "Hardware eventually fails. Software eventually works."
    fill_in "author", with: "Eva"
    click_on "Speichern"
    check_this_page page, nil, /Das Zitat wurde aktualisiert. Der Autor .* wurde nicht geändert./
    check_page page, quotation_url(id: 1), nil, /Zitat:.*Hardware eventually fails. Software eventually works./
    check_this_page page, nil, /Autor:.*Friedrich Schiller/
  end
  test "author autocompletion create quote" do
    do_login
    visit new_quotation_url
    fill_in "author", with: "Schiller"
    assert page.has_css?(".animated") # wait for autocompletion
    fill_in "quotation_quotation", with: "Die Sterne lügen nicht."
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde angelegt."
    new_quote = Quotation.last
    check_page page, quotation_url(id: new_quote), nil, /Zitat:.*Die Sterne lügen nicht./
    check_this_page page, nil, /Autor:.*Friedrich Schiller/
    # check session variable author_id is eaten
    visit new_quotation_url
    fill_in "quotation_quotation", with: "Die Axt im Haus erspart den Zimmermann."
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde angelegt."
    new_quote = Quotation.last
    check_page page, quotation_url(id: new_quote), nil, /Zitat:.*Die Axt im Haus erspart den Zimmermann./
    check_this_page page, nil, /Autor:.*unknown/
  end
  test "author autocompletion edit second quote bug #57" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten" # 1st quote has author id 1 "Barbara"
    check_page_source page, /Barbara/ # is given in HTML form as input value, therefore to user check_page_source
    check_page page, edit_quotation_url(id: 2), "h1", "Zitat bearbeiten" # 2nd quote has author id 2 "second author"
    check_page_source page, /second author/
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde aktualisiert."
    check_this_page page, nil, /Autor:.*second author.*/
  end
  test "author autocompletion can use non-public authors" do
    new_author_name = "Zátopek"
    new_quote = "Vogel fliegt, Fisch schwimmt, Mensch läuft."
    do_login
    check_page page, new_author_url, "h1", "Autor anlegen"
    fill_in "author_name", with: new_author_name
    click_on "Speichern"
    check_this_page page, "h1", "Autor" # do it before to have Capybara wait until and new author and url is existing
    check_page page, author_url(id: Author.find_by_name(new_author_name)), "h1", "Autor"
    visit new_quotation_url
    fill_in "author", with: new_author_name
    fill_in "quotation_quotation", with: new_quote
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde angelegt."
    check_page page, quotation_url(id: Quotation.last), nil, /Zitat:.*#{new_quote}/
    check_this_page page, nil, /Autor:.*#{new_author_name}/
  end

  test "edit someone else quote" do
    do_login :second_user, :second_user_password
    check_page page, quotation_url(id: Quotation.find_by_quotation("public_false")), "h1", /Zugriff wurde verweigert .* 403/
  end

  test "try to edit quote from someone else" do
    check_page page, quotation_url(id: Quotation.find_by_quotation("public_false")), "h1", /Zugriff wurde verweigert .* 403/
  end

  test "create new quote and delete" do
    do_login
    visit new_quotation_url
    fill_in "quotation_quotation", with: "Yes, we can."
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde angelegt."
    new_quote = Quotation.last
    check_page page, quotation_url(id: new_quote), nil, /Öffentlich:.*Nein/
    # delete
    visit quotations_url
    accept_alert do
      find("img[title='Löschen']", match: :first).click
    end
    check_page page, quotation_url(id: new_quote), "h1", /Seite nicht gefunden .* 404/
  end

  test "failed to save new quote" do
    do_login
    visit new_quotation_url
    fill_in "quotation_quotation", with: "Yes, we can."
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde angelegt."
    # 2nd try
    visit new_quotation_url
    fill_in "quotation_quotation", with: "Yes, we can."
    click_on "Speichern"
    check_this_page page, nil, "dieses Zitat gibt es bereits"
  end

  test "GET creating new quote requires login" do
    check_page page, new_quotation_url, "h1", /Zugriff wurde verweigert .* 403/
  end

  test "admin needed to list not public quotes" do
    check_page page, quotations_list_no_public_url, nil, "Kein Administrator!"
  end
  test "list not public quotes" do
    do_login :admin_user, :admin_user_password
    check_this_page page, nil, "Hallo admin_user, schön dass Du da bist."
    check_page page, quotations_list_no_public_url, "h1", "Nicht-Öffentliche Zitate"
  end

  test "trailing slash" do
    check_page page, quotations_url + "/", "h1", "Zitat"
    assert_equal "Zitat-Service – Zitate", page.title
    # redirected URL w/o slash
    assert_equal page.current_url, quotations_url
  end

  test "pagination with trailing slash" do
    url = quotations_url + "?page=2/"
    check_page page, url, "h1", "Zitat"
    check_this_page page, nil, "Aktionen"
    # redirected URL w/o slash
    assert_equal page.current_url, url.chop
  end

  test "pagination not found" do
    url = quotations_url + "?page=420000"
    check_page page, url, "h1", "400"
    # wrong URL have to be shown
    check_this_page page, nil, url
    check_page_source page, /href=".*quote\/issues/
  end

  # as seen from Internet, getting HTTP error 500 from ActionController::BadRequest with #54
  test "ActionController BadRequest" do
    check_page page, "/quotations?page=2&pattern=-6177%25%27%20UNION%20ALL%20SELECT%201693%2C1693%2C1693%2C1693%2C1693%2C1693%2C1693%2C1693%2CCONCAT%280x7171767a71%2C0x4e4c6547675956596d4e4d6958496a6f6a4a4c494f586b5a756745544c6a494a436f596b724b6e47%2C0x71717a6a71%29%2", "h1", "400"
  end

  test "ActionController BadRequest2" do
    url = "/quotations?pattern=%ö"
    check_page page, url, "h1", "400"
    # wrong URL have to be shown
    check_this_page page, nil, url
    check_page_source page, /href=".*quote\/issues/
  end

  test "new and autocomplete one category with unique input" do
    quote = "Yes, we can."
    do_login
    visit new_quotation_url
    fill_in "quotation_quotation", with: quote
    fill_in "category", with: "tw"
    check_this_page page, nil, /Kategorie.*two/ # wait for autocompletion
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde angelegt."
    check_page page, quotation_url(id: Quotation.last), nil, /Zitat:.*#{quote}/
    check_this_page page, nil, /Kategorien:.*two/
  end

  test "new and autocomplete two categories with unique input" do
    quote = "Shoot for the moon. Even if you miss, you'll land among the stars."
    do_login
    visit new_quotation_url
    fill_in "quotation_quotation", with: quote
    fill_in "category", with: "tw"
    check_this_page page, nil, /Kategorie.*two/ # wait for autocompletion
    fill_in "category", with: "th"
    check_this_page page, nil, /Kategorie.*three/ # wait for autocompletion
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde angelegt."
    check_page page, quotation_url(id: Quotation.last), nil, /Zitat:.*#{quote}/
    check_this_page page, nil, /Kategorien:.*two.*/
    check_this_page page, nil, /Kategorien:.*three.*/
  end

  test "new and autocomplete one hundred categories with unique input" do
    quote = "Time not important. Only live important."
    do_login
    visit new_quotation_url
    fill_in "quotation_quotation", with: quote
    1101.upto(1200) do |i|
      fill_in "category", with: "#{i}" # 1101 ... 1200
      check_this_page page, nil, /Kategorie.*#{i}_category/ # wait for autocompletion
    end
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde angelegt."
    check_page page, quotation_url(id: Quotation.last), nil, /Zitat:.*#{quote}/
    1101.upto(1200) do |i|
      check_this_page page, nil, /Kategorien:.*#{i}_category/
    end
  end

  test "new and autocomplete category by click" do
    quote = "A warrior never does what you expect."
    do_login
    visit new_quotation_url
    fill_in "quotation_quotation", with: quote
    fill_in "author", with: "Eva"
    check_this_page page, "div", "Eva 10" # wait for autocompletion
    click_on "Eva 10"
    fill_in "category", with: "100"
    check_this_page page, "div", "1001_category" # wait for autocompletion
    click_on "1001_category"
    check_this_page page, nil, /Kategorie.*1001_category/ # wait for autocompletion
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde angelegt."
    check_this_page page, nil, /Autor:.*Eva 10/
    check_this_page page, nil, /Kategorien:.*1001_category/
  end

  test "delete one and only category" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    check_this_page page, nil, /Kategorie.*#{Category.first.category}/ # Quote.first has Category.first, right?
    click_on Category.first.category
    click_on "Speichern"
    check_this_page page, nil, "Das Zitat wurde aktualisiert."
    check_this_page page, nil, /Kategorien:$/ # empty?
  end

  test "recommended categories" do
    quote = "This is a quote which contains categories 1013_category and 1042_category"
    do_login
    # first in new quote
    visit new_quotation_url
    fill_in "quotation_quotation", with: quote
    fill_in "category", with: " " # to start creating the recommendation list
    check_this_page page, nil, "mit einem Klick hinzufügen: " # wait for autocompletion
    click_on "1013_category"
    check_this_page page, "div", "1013_category" # wait for autocompletion
    click_on "1042_category"
    check_this_page page, "div", "1042_category" # wait for autocompletion
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde angelegt."
    check_this_page page, nil, /Kategorien:.*1013_category/
    check_this_page page, nil, /Kategorien:.*1042_category/
    # delete one category
    visit quotation_url(id: Quotation.last)
    click_on "Stift"
    check_this_page page, "h1", "Zitat bearbeiten"
    click_on "1013_category"
    check_this_page page, nil, "1 Kategorie" # wait for autocompletion
    click_on "Speichern"
    check_this_page page, nil, "Das Zitat wurde aktualisiert."
    check_this_page page, nil, /Kategorien:.*1042_category$/
    # add recommended category on existing quote
    click_on "Stift"
    check_this_page page, "h1", "Zitat bearbeiten"
    click_on "1013_category"
    check_this_page page, "div", "1013_category" # wait for autocompletion
    click_on "Speichern"
    check_this_page page, nil, "Das Zitat wurde aktualisiert."
    check_this_page page, nil, /Kategorien:.*1013_category/
    check_this_page page, nil, /Kategorien:.*1042_category/
  end

  test "checking create and update times" do
    do_login
    visit new_quotation_url
    fill_in "quotation_quotation", with: "Yes, we can."
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde angelegt."
    new_quote = Quotation.last
    assert new_quote.created_at != nil
    assert new_quote.updated_at != nil
    assert_equal new_quote.created_at, new_quote.updated_at
  end

  test "check update time changes with quote" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "quotation_quotation", with: "Yes We Can"
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde aktualisiert."
    check_this_page page, nil, /Zitat:.*Yes We Can/
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert last_updated < changed_quote.updated_at, "last_updated=#{last_updated} < changed.updated_at=#{changed_quote.updated_at}"
  end

  test "check update time changes with author" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "author", with: "schiller"
    assert page.has_css?(".animated") # wait for autocompletion
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde aktualisiert."
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert last_updated < changed_quote.updated_at, "last_updated=#{last_updated} < changed.updated_at=#{changed_quote.updated_at}"
  end

  test "check update time changes with source" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "quotation_source", with: "The Internet"
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde aktualisiert."
    check_this_page page, nil, /Quelle:.*The Internet/
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert last_updated < changed_quote.updated_at, "last_updated=#{last_updated} < changed.updated_at=#{changed_quote.updated_at}"
  end

  test "check update time changes with link" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "quotation_source_link", with: "https://github.com/muhme/quote"
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde aktualisiert."
    check_this_page page, nil, /Link zur Quelle:.*github.com\/muhme\/quote/
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert last_updated < changed_quote.updated_at, "last_updated=#{last_updated} < changed.updated_at=#{changed_quote.updated_at}"
  end

  test "check update time changes with adding category" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "category", with: "tw"
    check_this_page page, nil, /Kategorie.*two/ # wait for autocompletion
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde aktualisiert."
    check_this_page page, nil, /Kategorien:.*two/
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert last_updated < changed_quote.updated_at, "last_updated=#{last_updated} < changed.updated_at=#{changed_quote.updated_at}"
  end

  test "check update time changes with removing category" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    click_on Category.first.category # remove "public_category"
    check_this_page page, "label", "Kategorien" # wait for autocompletion
    click_on "Speichern"
    check_this_page page, nil, "Zitat wurde aktualisiert."
    check_this_page page, nil, /Kategorien:$/
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert last_updated < changed_quote.updated_at, "last_updated=#{last_updated} < changed.updated_at=#{changed_quote.updated_at}"
  end

  test "check update time does not change without change" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    last_quote = Quotation.find(1).quotation
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Zitat bearbeiten"
    fill_in "quotation_quotation", with: "cheesecake"
    fill_in "quotation_quotation", with: last_quote
    click_on "Speichern"
    check_this_page page, nil, "Das Zitat wurde nicht geändert."
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert_equal last_updated, changed_quote.updated_at
  end

  # NICE cannot delete quote created by another user

end
