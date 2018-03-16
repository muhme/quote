require "application_system_test_case"

class QuotationsTest < ApplicationSystemTestCase

  test "quotations" do
    check_page page, "/quotations", "h1", "Zitat", 300
    assert_equal page.title, "Zitat-Service - Zitate"
  end

  test "list by category" do
    check_page page, "quotations/list_by_category/" + Category.first.id.to_s, "h1", "Zitate für die Kategorie", 200
    assert_equal page.title, "Zitat-Service - Zitate zu public_category"
  end

  test "list by user" do
    check_page page, "quotations/list_by_user/" + User.first.login.to_s, "h1", "Zitate von", 200
    assert_equal page.title, "Zitat-Service - Zitate des Benutzers first_user"
  end
  
  test "list by author" do
    check_page page, "quotations/list_by_author/" + Author.first.id.to_s, "h1", "Zitate für den Autor", 200
    assert_equal page.title, "Zitat-Service - Zitate von public_author"
  end
  
  test "show quote" do
    check_page page, quotation_url(Quotation.find_by_quotation('public_quotation')), "h1", "Zitat", 200
    assert_equal page.title, "Zitat-Service - Zitat von public_author"
  end
  
  # NICE create quote, check is not public
  # NICE not allowed to create quote without login
  # NICE delete own created quote
  # NICE cannot delete quote created by another user

end
