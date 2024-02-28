require "application_system_test_case"

class QuotationsTest < ApplicationSystemTestCase
  test "quotations" do
    2.times do # 1st run w/o, 2nd w/ login
      check_page page, quotations_url, "h1", "Quotes"
      assert_equal "Zitat-Service – Quotes", page.title
      check_this_page page, "h1", "2 Quotes"
      uncheck 'locale_en'
      check_this_page page, "h1", /10[\.,][0-9]{3} Quotes/ # actual 10,007
      check 'locale_uk'
      check_this_page page, "h1", "0 Quotes"
      do_login
    end
  end

  test "list by category" do
    2.times do # 1st run w/o, 2nd w/ login
      2.times do # 1st no locale is selected, 2nd :en
        check_page page, "quotations/list_by_category/" + Category.first.id.to_s, "h1",
                   "2 Quotes for the category public_category"
        assert_equal "Zitat-Service – Quotes to public_category", page.title
        check 'locale_en'
      end
      uncheck 'locale_en'
      check 'locale_uk'
      check_this_page page, "h1", "0 Quotes for the category public_category"
      do_login
    end
  end
  test "failed to list not existing category" do
    check_page page, "quotations/list_by_category/bla", nil, 'Cannot find a category with the ID="bla"!'
  end

  test "list by user" do
    2.times do # 1st run w/o, 2nd w/ login
      2.times do # 1st no locale is selected, 2nd :en
        check_page page, "quotations/list_by_user/#{User.first.id}", "h1",
                   /10[\.,][0-9]{3} Quotes of the user "first_user"/ # actual 10,006
        assert_equal "Zitat-Service – Quotes of the user first_user", page.title
        # 2nd time :en
        check 'locale_en'
      end
      uncheck 'locale_en'
      check 'locale_uk'
      check_this_page page, "h1", '0 Quotes of the user "first_user"'
      do_login
    end
  end
  test "try to list for not existing user" do
    check_page page, "quotations/list_by_user/leon3", nil, 'Cannot find a user with ID="leon3"!'
  end

  test "list by author" do
    2.times do # 1st run w/o, 2nd w/ login
      2.times do # 1st no locale is selected, 2nd :en
        check_page page, "quotations/list_by_author/#{authors(:schiller).id}", "h1",
                   "1 Quote by Friedrich Schiller"
        assert_equal "Zitat-Service – Quotes from Friedrich Schiller", page.title
        # 2nd time :en
        check 'locale_de'
      end
      uncheck 'locale_de'
      check 'locale_en'
      check_this_page page, "h1", "0 Quotes by Friedrich Schiller"
      do_login
    end
  end
  test "failed to list not existing author" do
    check_page page, "quotations/list_by_author/bli", nil, 'Cannot find an author with the ID="bli"!'
  end

  test "show quote" do
    check_page page, quotation_url(id: 1), "h1", "Quote"
    assert_equal "Zitat-Service – Quote from Barbara", page.title
  end

  test "list and show non-public" do
    # create non-public category and non-public quote
    npc = "non-public-category"
    npq = "non-public-quote"
    do_login
    check_page page, new_category_url, "h1", "Create Category"
    fill_in "category_name_en", with: npc
    click_on "Save"
    check_this_page page, "h2", "Comments" # let Capybara wait until the new category exists
    visit new_quotation_url
    fill_in "quotation_quotation", with: npq
    fill_in "author", with: authors(:public_false).name
    fill_in "category", with: npc
    check_this_page page, nil, /category.*#{npc}/ # wait for autocompletion
    click_on "Save"
    check_this_page page, nil, "quote has been added"
    visit logout_path

    # try it w/o login, as user and as admin
    3.times do |i|
      visit logout_path if i == 0
      do_login if i == 1
      do_login :admin_user, :admin_user_password if i == 2
      check_page page, quotations_path, nil, npq
      check_page page, quotations_path(pattern: npq), nil, npq
      check_page page, "/quotations/list_by_category/#{Category.last.id}", nil, npq
      check_page page, "/quotations/list_by_user/#{users(:first_user).id}", nil, npq
      check_page page, "/quotations/list_by_user/#{users(:first_user).id}", nil, npq
      check_page page, "/quotations/list_by_author/#{authors(:public_false).id}", nil, npq
    end
  end

  # linking author's name with that author's quotes #13
  # linking author from quote #58
  test "multiple quotes with author link" do
    # quote #1 is from author #1 which has multiple quotes
    check_page page, "quotations/1", "h1", "Quote"
    check_page_source page, /href=".*\/quotations\/list_by_author\//
    check_this_page page, nil, /Author:.*quotes\)/
  end
  test "single quote with author link" do
    # quote #3 is from third author which has only one single quote
    check_page page, "quotations/3", "h1", "Quote"
    assert false, "page \"#{page.current_url}\" shows authors quotes" if page.has_text? "quotes)"
    assert false, "page \"#{page.current_url}\" shows authors quotes" if page.has_text? "quote)"
  end
  # same for user, has to be linked if at least one user exists
  test "multiple quotes with user link" do
    # quote #1 is from user #1 which has multiple quotes
    check_page page, "quotations/1", "h1", "Quote"
    check_page_source page, /href=".*\/quotations\/list_by_user\//
  end
  test "single quote with user link" do
    # quote #3 is from author #2 which has only one single quote
    check_page page, "quotations/3", "h1", "Quote"
    check_page_source page, /href=".*\/quotations\/list_by_user\//
  end

  test "quotes for languages" do
    check_page page, quotations_url + "?locales=en", "h1", "Quote"
    check_page page, quotations_url + "?locales=de", "h1", "Quote"
    check_page page, quotations_url + "?locales=ja,uk", "h1", "Quote"
    check_page page, quotations_url + "?locales=", "h1", "Quote"
    check_page page, quotations_url + "?locales=XX", "h1", "Quote"
    check_page page, quotations_url(locale: :de) + "?locales=de", "h1", "Zitat"
  end

  test "edit own quote" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "author", with: "schiller"
    fill_in "quotation_source", with: "jo!"
    assert page.has_css?(".animated") # wait for autocompletion
    select 'Українська', from: 'quotation_locale'
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_page page, quotation_url(id: 1), nil, /Original source:.*jo!/
    check_this_page page, nil, /Author:.*Friedrich Schiller/
    check_this_page page, nil, "🇺🇦 UK"
  end
  test "edit own quote fails" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "quotation_quotation", with: "jo!"
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_page page, quotation_url(id: 1), nil, /Quote:.*jo!/
    # try to update second quote to exactly the same content as 1st quote
    check_page page, edit_quotation_url(id: 2), "h1", "Edit quote"
    fill_in "quotation_quotation", with: "jo!"
    click_on "Save"
    check_this_page page, nil, "Quote has already been taken"
  end

  test "author autocompletion select one in the list" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "author", with: "Eva"
    click_on "Eva 10"
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_this_page page, nil, /Author:.*Eva 10/
  end
  test "author autocompletion give name" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "author", with: "Eva 1"
    check_this_page page, "div#authors_list", /Eva 1/
    fill_in "author", with: "Eva 19"
    assert page.has_css?(".animated") # wait for autocompletion
    check_page_source page, 'value="Eva 19"'
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_this_page page, nil, /Author:.*Eva 19/
  end
  test "author autocompletion multiple authors" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "author", with: "Eva"
    click_on "Save"
    check_this_page page, nil, 'The quote has not been changed. The author "Barbara" has not been changed.'
    check_this_page page, nil, /Author:.*Barbara/
  end
  test "author autocompletion not existing author" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "author", with: "brabbel zabbel"
    click_on "Save"
    check_this_page page, nil, 'The quote has not been changed. The author "Barbara" has not been changed.'
    check_this_page page, nil, /Author:.*Barbara/
  end
  test "author autocompletion change quote" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "author", with: "Schiller"
    assert page.has_css?(".animated") # wait for autocompletion
    fill_in "quotation_quotation", with: "Those who do not venture beyond reality will never conquer the truth."
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_page page, quotation_url(id: 1), nil,
               /Quote:.*Those who do not venture beyond reality will never conquer the truth./
    check_this_page page, nil, /Author:.*Friedrich Schiller/
    # existing author is not changed
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "quotation_quotation", with: "the apple of discord tastes bitter"
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_page page, quotation_url(id: 1), nil, /Quote:.*the apple of discord tastes bitter/
    check_this_page page, nil, /Author:.*Friedrich Schiller/
    # autocomplete with list > 1 doesn't change author
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "quotation_quotation", with: "Hardware eventually fails. Software eventually works."
    fill_in "author", with: "Eva"
    click_on "Save"
    check_this_page page, nil, /The quote has been updated. The author .* has not been changed./
    check_page page, quotation_url(id: 1), nil, /Quote:.*Hardware eventually fails. Software eventually works./
    check_this_page page, nil, /Author:.*Friedrich Schiller/
  end
  test "author autocompletion create quote" do
    do_login
    visit new_quotation_url
    fill_in "author", with: "Schiller"
    assert page.has_css?(".animated") # wait for autocompletion
    fill_in "quotation_quotation", with: "The stars do not lie."
    click_on "Save"
    check_this_page page, nil, "quote has been added."
    new_quote = Quotation.last
    check_page page, quotation_url(id: new_quote), nil, /Quote:.*The stars do not lie./
    check_this_page page, nil, /Author:.*Friedrich Schiller/
    # check session variable author_id is eaten
    visit new_quotation_url
    fill_in "quotation_quotation", with: "The axe in the house saves the carpenter."
    click_on "Save"
    check_this_page page, nil, "quote has been added."
    new_quote = Quotation.last
    check_page page, quotation_url(id: new_quote), nil, /Quote:.*The axe in the house saves the carpenter./
    check_this_page page, nil, /Author:.*unknown/
  end
  test "author autocompletion edit second quote bug #57" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote" # 1st quote has author id 1 "Barbara"
    check_page_source page, /Barbara/ # is given in HTML form as input value, therefore to user check_page_source
    check_page page, edit_quotation_url(id: 2), "h1", "Edit quote" # 2nd quote has author id 2 "second author"
    check_page_source page, /second author/
    click_on "Save"
    check_this_page page, nil, 'The quote has not been changed.'
    check_this_page page, nil, /Author:.*second author.*/
  end
  test "author autocompletion can use non-public authors" do
    new_author_name = "Zátopek"
    new_quote = "Bird flies, fish swims, man walks."
    do_login
    check_page page, new_author_url, "h1", "Author create"
    fill_in "author_name", with: new_author_name
    click_on "Save"
    check_this_page page, nil, /The author .* has been created./ # wait until and new author is existing
    check_page page, author_url(id: Author.last), "h1", "Author"
    visit new_quotation_url
    fill_in "author", with: new_author_name
    fill_in "quotation_quotation", with: new_quote
    assert page.has_css?(".animated") # wait for autocompletion
    click_on "Save"
    check_this_page page, nil, "quote has been added."
    check_page page, quotation_url(id: Quotation.last), nil, /Quote:.*#{new_quote}/
    check_this_page page, nil, /Author:.*#{new_author_name}/
  end

  test "show non-public quote w/ someone else login" do
    do_login :second_user, :second_user_password
    check_page page, quotation_url(id: Quotation.find_by_quotation("public_false")), "h1", "Quote"
  end

  test "show non-public quote w/o login" do
    check_page page, quotation_url(id: Quotation.find_by_quotation("public_false")), "h1", "Quote"
  end

  test "create new quote and delete" do
    do_login
    visit new_quotation_url
    fill_in "quotation_quotation", with: "Слава Україні!"
    select 'Українська', from: 'quotation_locale'
    click_on "Save"
    check_this_page page, nil, "quote has been added."
    new_quote = Quotation.last
    check_page page, quotation_url(id: new_quote), nil, /Public:.*No/
    check_this_page page, nil, "🇺🇦 UK"
    # delete
    visit quotations_url
    check 'locale_uk'
    accept_alert do
      find("img[title='Delete']", match: :first).click
    end
    check_page page, quotation_url(id: new_quote), "h1", /Page not found .* 404/
  end

  test "failed to save new quote" do
    do_login
    visit new_quotation_url
    fill_in "quotation_quotation", with: "Yes, we can."
    click_on "Save"
    check_this_page page, nil, "quote has been added."
    # 2nd try
    visit new_quotation_url
    fill_in "quotation_quotation", with: "Yes, we can."
    click_on "Save"
    check_this_page page, nil, "Quote has already been taken"
  end

  test "GET creating new quote requires login" do
    check_page page, new_quotation_url, "h1", /Access Denied .* 403/
  end

  test "admin needed to list not public quotes" do
    check_page page, quotations_list_no_public_url, "h1", /Access Denied .* 403/
    check_this_page page, nil, "Not an Administrator!"
  end
  test "list not public quotes" do
    do_login :admin_user, :admin_user_password
    check_this_page page, nil, "Hello admin_user, nice to have you here."
    check_page page, quotations_list_no_public_url, "h1", "Non-public Quotes"
  end

  test "trailing slash" do
    check_page page, quotations_url + "/", "h1", "Quote"
    assert_equal "Zitat-Service – Quotes", page.title
    # redirected URL w/o slash
    assert_equal page.current_url, quotations_url
  end

  test "pagination with trailing slash" do
    url = quotations_url + "?locales=&page=2/"
    check_page page, url, "h1", "Quote"
    check_this_page page, nil, "Actions"
    # redirected URL w/o slash
    assert_equal page.current_url, url.chop
  end

  test "pagination not found" do
    url = quotations_url + "?page=420000"
    check_page page, url, "h1", /Bad Request .* 400/
    check_this_page page, nil, /Page 420000 does not exist!/
    # wrong URL have to be shown
    check_this_page page, nil, url
    check_page_source page, /href=".*quote\/issues/
  end

  # as seen from Internet, getting HTTP error 500 from ActionController::BadRequest with #54
  test "ActionController BadRequest" do
    # rubocop:disable Layout/LineLength
    check_page page,
               "/quotations?page=2&pattern=-6177%25%27%20UNION%20ALL%20SELECT%201693%2C1693%2C1693%2C1693%2C1693%2C1693%2C1693%2C1693%2CCONCAT%280x7171767a71%2C0x4e4c6547675956596d4e4d6958496a6f6a4a4c494f586b5a756745544c6a494a436f596b724b6e47%2C0x71717a6a71%29%2", "h1", /HTTP.*400/
    # rubocop:disable Layout/LineLength
  end

  test "ActionController BadRequest2" do
    url = "/quotations?pattern=%ö"
    check_page page, url, "h1", /Bad Request .* 400/
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
    check_this_page page, nil, /category.*two/ # wait for autocompletion
    click_on "Save"
    check_this_page page, nil, "quote has been added."
    check_page page, quotation_url(id: Quotation.last), nil, /Quote:.*#{quote}/
    check_this_page page, nil, /Categories:.*two/
  end

  test "new and autocomplete two categories with unique input" do
    quote = "Shoot for the moon. Even if you miss, you'll land among the stars."
    do_login
    visit new_quotation_url
    fill_in "quotation_quotation", with: quote
    fill_in "category", with: "tw"
    check_this_page page, nil, /categor.*two/ # wait for autocompletion
    fill_in "category", with: "th"
    check_this_page page, nil, /categor.*three/ # wait for autocompletion
    click_on "Save"
    check_this_page page, nil, "quote has been added."
    check_page page, quotation_url(id: Quotation.last), nil, /Quote:.*#{quote}/
    check_this_page page, nil, /Categories:.*two/
    check_this_page page, nil, /Categories:.*three/
  end

  test "new and autocomplete one hundred categories with unique input" do
    quote = "Time not important. Only live important."
    do_login
    visit new_quotation_url
    fill_in "quotation_quotation", with: quote
    1101.upto(1200) do |i|
      fill_in "category", with: "#{i}" # 1101 ... 1200
      # sleep 1 # TODO
      check_this_page page, nil, /categor.*#{i}_category/ # wait for autocompletion
    end
    click_on "Save"
    check_this_page page, nil, "quote has been added."
    check_page page, quotation_url(id: Quotation.last), nil, /Quote:.*#{quote}/
    1101.upto(1200) do |i|
      check_this_page page, nil, /Categories:.*#{i}_category/
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
    check_this_page page, nil, /category.*1001_category/ # wait for autocompletion
    click_on "Save"
    check_this_page page, nil, "quote has been added."
    check_this_page page, nil, /Author:.*Eva 10/
    check_this_page page, nil, /Categories:.*1001_category/
  end

  test "delete one and only category" do
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    check_this_page page, nil, /category.*#{Category.first.category}/ # Quote.first has Category.first, right?
    click_on Category.first.category
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_this_page page, nil, /Categories:$/ # empty?
  end

  test "recommended categories" do
    quote = "This is a quote which contains categories 1013_category and 1042_category"
    do_login
    # first in new quote
    visit new_quotation_url
    fill_in "quotation_quotation", with: quote
    fill_in "category", with: " " # to start creating the recommendation list
    check_this_page page, nil, "add with one click:" # wait for autocompletion
    click_on "1013_category"
    check_this_page page, "div", "1013_category" # wait for autocompletion
    click_on "1042_category"
    check_this_page page, "div", "1042_category" # wait for autocompletion
    click_on "Save"
    check_this_page page, nil, "quote has been added."
    check_this_page page, nil, /Categories:.*1013_category/
    check_this_page page, nil, /Categories:.*1042_category/
    # delete one category
    visit quotation_url(id: Quotation.last)
    click_on "Pencil"
    check_this_page page, "h1", "Edit quote"
    click_on "1013_category"
    check_this_page page, nil, "1 category" # wait for autocompletion
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_this_page page, nil, /Categories:.*1042_category$/
    # add recommended category on existing quote
    click_on "Pencil"
    check_this_page page, "h1", "Edit quote"
    click_on "1013_category"
    check_this_page page, "div", "1013_category" # wait for autocompletion
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_this_page page, nil, /Categories:.*1013_category/
    check_this_page page, nil, /Categories:.*1042_category/
  end

  test "checking create and update times" do
    do_login
    visit new_quotation_url
    fill_in "quotation_quotation", with: "Yes, we can."
    click_on "Save"
    check_this_page page, nil, "quote has been added."
    new_quote = Quotation.last
    assert new_quote.created_at != nil
    assert new_quote.updated_at != nil
    assert_equal new_quote.created_at, new_quote.updated_at
  end

  test "check update time changes with quote" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "quotation_quotation", with: "Yes We Can"
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_this_page page, nil, /Quote:.*Yes We Can/
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert last_updated < changed_quote.updated_at,
           "last_updated=#{last_updated} < changed.updated_at=#{changed_quote.updated_at}"
  end

  test "check update time changes with author" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "author", with: "schiller"
    assert page.has_css?(".animated") # wait for autocompletion
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert last_updated < changed_quote.updated_at,
           "last_updated=#{last_updated} < changed.updated_at=#{changed_quote.updated_at}"
  end

  test "check update time changes with source" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "quotation_source", with: "The Internet"
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_this_page page, nil, /Original source:.*The Internet/
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert last_updated < changed_quote.updated_at,
           "last_updated=#{last_updated} < changed.updated_at=#{changed_quote.updated_at}"
  end

  test "check update time changes with link" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "quotation_source_link", with: "https://github.com/muhme/quote"
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_this_page page, nil, /Link to original source:.*github.com\/muhme\/quote/
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert last_updated < changed_quote.updated_at,
           "last_updated=#{last_updated} < changed.updated_at=#{changed_quote.updated_at}"
  end

  test "check update time changes with adding category" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "category", with: "tw"
    check_this_page page, nil, /categor.*two/ # wait for autocompletion
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_this_page page, nil, /Categories:.*two/
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert last_updated < changed_quote.updated_at,
           "last_updated=#{last_updated} < changed.updated_at=#{changed_quote.updated_at}"
  end

  test "check update time changes with removing category" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    click_on Category.first.category # remove "public_category"
    check_this_page page, nil, "add with one click" # wait for autocompletion
    click_on "Save"
    check_this_page page, nil, "The quote has been updated."
    check_this_page page, nil, /Categories:$/
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert last_updated < changed_quote.updated_at,
           "last_updated=#{last_updated} < changed.updated_at=#{changed_quote.updated_at}"
  end

  test "check update time does not change without change" do
    last_created = Quotation.find(1).created_at
    last_updated = Quotation.find(1).updated_at
    last_quote = Quotation.find(1).quotation
    do_login
    check_page page, edit_quotation_url(id: 1), "h1", "Edit quote"
    fill_in "quotation_quotation", with: "cheesecake"
    fill_in "quotation_quotation", with: last_quote
    click_on "Save"
    check_this_page page, nil, "The quote has not been changed."
    changed_quote = Quotation.find(1)
    assert_equal last_created, changed_quote.created_at
    assert_equal last_updated, changed_quote.updated_at
  end

  # NICE cannot delete quote created by another user
end
