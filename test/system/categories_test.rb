require "application_system_test_case"

class CategoriesTest < ApplicationSystemTestCase

  test "category" do
    check_page page, "/categories", "h1", "Kategorie", 300
  end

  test "category_letter_a" do
    check_page page, "/categories/list_by_letter/A", "h1", "Kategorie", 200
  end

  test "category_not_letter" do
    check_page page, "/categories/list_by_letter/*", "h1", "Kategorie", 200
  end

  test "show category" do
    check_page page, "/categories/" + Category.first.id.to_s, "h1", "Kategorie", 200
  end

end