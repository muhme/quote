require "application_system_test_case"

class QuotationsTest < ApplicationSystemTestCase

  test "quotations" do
    check_page page, "/quotations", "h1", "Zitate", 300
  end

  test "list by category" do
    check_page page, "quotations/list_by_category/" + Category.first.id.to_s, "h1", "Zitate für die Kategorie", 200
  end

  test "list by user" do
    check_page page, "quotations/list_by_user/" + User.first.id.to_s, "h1", "Zitate von", 200
  end
  
  test "list by author" do
    check_page page, "quotations/list_by_author/" + Author.first.id.to_s, "h1", "Zitate für den Autor", 200
  end
  
  test "show quote" do
    check_page page, "/quotations/" + Quotation.first.id.to_s, "h1", "Zitat", 200
  end

end
