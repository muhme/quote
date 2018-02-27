require "application_system_test_case"

class AuthorsTest < ApplicationSystemTestCase

  test "author" do
    check_page page, "/authors", "h1", "Autor", 250
  end

  test "author_letter_a" do
    check_page page, "/authors/list_by_letter/A", "h1", "Autor", 200
  end

  test "author_not_letter" do
    check_page page, "/authors/list_by_letter/*", "h1", "Autor", 200
  end
  
  test "show author" do
    check_page page, "/authors/" + Author.first.id.to_s, "h1", "Autor", 200
  end

end