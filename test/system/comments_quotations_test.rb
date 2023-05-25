require "application_system_test_case"

class CommentsQuotationsTest < ApplicationSystemTestCase
  
  test "show existing comment" do
    check_page page, quotation_url(locale: "es", id: quotations(:with_one_comment)), "h1", "Cita"
    check_this_page page, "h2", "Comentarios"
    check_this_page page, "p", "Inicia sesión con Iniciar sesión para añadir comentarios aquí."
    # user, created and updated
    check_this_page page, nil, /second_user.*comentado en 01.05.2023.*actualizado el 10.05.2023/
    # comment itself
    check_this_page page, nil, "Comentarios en español for quotation \"with_one_comment\""
    # locale
    check_this_page page, "span.flags", "ES"
  end

  test "add new comment" do
    do_login :second_user, :second_user_password
    check_page page, quotation_url(locale: "en", id: quotations(:with_one_comment)), "h1", "Quote"
    fill_in "comment_comment", with: "Test Comment"
    click_on "Add"
    check_this_page page, nil, "Test Comment"
    check_this_page page, "span.flags", "EN"
    # reload quotation
    check_page page, quotation_url(locale: "en", id: quotations(:with_one_comment)), "h1", "Quote"
    check_this_page page, nil, "Test Comment"
    check_this_page page, "span.flags", "EN"
  end

  test "no empty comments allowed" do
    do_login :second_user, :second_user_password
    check_page page, quotation_url(locale: "en", id: quotations(:with_one_comment)), "h1", "Quote"
    fill_in "comment_comment", with: ""
    click_on "Add"
    check_this_page page, "h2", "Error"
    check_this_page page, nil, "Comment can't be blank"
  end

  test "edit comment and language as own user" do
    do_login :second_user, :second_user_password
    check_page page, quotation_url(locale: "de", id: quotations(:with_one_comment)), "h1", "Zitat" # Quotation
    click_on "Stift" # pencil
    fill_in "edit_comment", with: "überschrieben" # overwritten
    click_on "Ändern" # Change
    check_this_page page, nil, "überschrieben"
    # reload quotation
    check_page page, quotation_url(locale: "en", id: quotations(:with_one_comment)), "h1", "Quote"
    check_this_page page, nil, "überschrieben"
    check_this_page page, "span.flags", "DE"
  end

  test "edit comment as admin" do
    do_login :admin_user, :admin_user_password
    check_page page, quotation_url(locale: "uk", id: quotations(:with_one_comment)), "h1", "Цитата" # Quotation
    page.find('img.edit_comment').click # as admin there are to pencil buttons, one for editing quotation and one for editing comment
    fill_in "edit_comment", with: "Слава Україні!" # Glory to Ukraine!
    click_on "Змінити" # Change
    check_this_page page, nil, "Слава Україні!"
    # reload quotation
    check_page page, quotation_url(locale: "en", id: quotations(:with_one_comment)), "h1", "Quote"
    check_this_page page, nil, "Слава Україні!"
    check_this_page page, "span.flags", "UK"
  end

  test "not allowed to edit someone else comment" do
    do_login
    check_page page, quotation_url(locale: "es", id: quotations(:with_one_comment)), "h1", "Cita" # Quotation
    assert_no_selector('img[class="edit_comment"]')
    visit logout_url
    do_login :second_user, :second_user_password
    check_page page, quotation_url(locale: "es", id: quotations(:with_one_comment)), "h1", "Cita"
    assert_selector('img[class="edit_comment"]')
  end

  test "delete comment" do
    old_comment = "Comentarios en español for quotation \"with_one_comment\""
    do_login :second_user, :second_user_password
    check_page page, quotation_url(locale: "ja", id: quotations(:with_one_comment)), "h1", "引用" # Quotation
    assert false, "missing #{old_comment}" unless page.has_text?(old_comment)
    accept_alert do
      find("img[title='削除']").click
    end
    assert false, "still exists #{old_comment}" unless page.has_no_text?(old_comment)
  end

end
