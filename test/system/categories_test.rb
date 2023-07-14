require "application_system_test_case"

class CategoriesTest < ApplicationSystemTestCase
  test "category" do
    check_page page, "/categories", "h1", "Categories"
    assert_equal "Zitat-Service – Categories", page.title
  end

  test "category list by letter" do
    check_page page, "/de/categories/list_by_letter/A", "h1", /Kategorie.* mit dem Anfangsbuchstaben „A”/
    assert_equal "Zitat-Service – Kategorien, die mit A beginnen", page.title
    check_page page, "/en/categories/list_by_letter/Y", "h1", /Categor.* with initial letter "Y"/
    assert_equal "Zitat-Service – Categories, starting with Y", page.title
    check_page page, "/es/categories/list_by_letter/X", "h1", /Categor.* con la letra inicial "X"/
    assert_equal "Zitat-Service – Categorías, empezando con X", page.title
    check_page page, "/ja/categories/list_by_letter/%E3%81%82", "h1", /カテゴリ の頭文字をとって「あ」/
    assert_equal "Zitat-Service – カテゴリ, あ で始まる", page.title
    check_page page, "/uk/categories/list_by_letter/%D0%91", "h1", /Категор.* – з початковою літерою "Б"/
    assert_equal "Zitat-Service – категорії, починаючи з Б", page.title
  end

  test "category not letter" do
    check_page page, "/categories/list_by_letter/*", "h1", "Categories"
    assert_equal "Zitat-Service – Categories, starting with *", page.title
  end

  test "show category" do
    check_page page, category_url(id: Category.i18n.find_by(category: "public_category")), "h1", "Category"
    assert_equal "Zitat-Service – Category public_category", page.title
  end

  test "list and show non-public" do
    check_page page, categories_path, nil, "two"
    check_page page, "/categories/list_by_letter/T", nil, "two"
    check_page page, category_url(id: Category.i18n.find_by(category: "two")), "h1", "Category"
    
    do_login
    check_page page, categories_path, nil, "two"
    check_page page, "/categories/list_by_letter/T", nil, "two"
    check_page page, category_url(id: Category.i18n.find_by(category: "two")), "h1", "Category"
    
    do_login :admin_user, :admin_user_password
    check_page page, categories_path, nil, "two"
    check_page page, "/categories/list_by_letter/T", nil, "two"
    check_page page, category_url(id: Category.i18n.find_by(category: "two")), "h1", "Category"
  end

  # /categories/new
  test "create and delete category" do
    new_category_name = "Smile"
    do_login
    check_page page, new_category_url(locale: :en), "h1", "Create Category"
    fill_in "category_name_en", with: new_category_name
    click_on "Save"
    check_this_page page, "h2", "Comments" # let Capybara wait until the new category exists
    cu = category_url(locale: :en, id: Category.i18n.find_by(locale: :en, category: new_category_name))
    check_page page, cu, "h1", "Category"
    check_this_page page, nil, "Smile" # en
    check_this_page page, nil, "Lächeln" # de
    check_this_page page, nil, "Sonría" # es
    check_this_page page, nil, "スマイル" # ja
    check_this_page page, nil, "Посміхнися" # uk
    # delete
    visit "/en/categories/list_by_letter/S"
    accept_alert do
      find("img[title='Delete']", match: :first).click
    end
    check_page page, cu, "h1", "HTTP status code 404"
  end

  test "create new empty category fails" do
    do_login
    check_page page, new_category_url(locale: :de), "h1", "Kategorie anlegen"
    fill_in "category_name_de", with: ""
    click_on "Speichern"
    check_this_page page, nil, "Kategorie kann nicht leer sein"
  end

  test "create new category with space works" do
    do_login
    check_page page, new_category_url(locale: :en), "h1", "Create Category"
    fill_in "category_name_en", with: "a b"
    click_on "Save"
    check_this_page page, "h1", "Category"
    check_this_page page, nil, "The category \"a b\" has been created."
  end

  test "create a new category that already exists fails" do
    do_login
    # Create category 'mountain'
    check_page page, new_category_url(locale: :en), "h1", "Create Category"
    fill_in "category_name_en", with: "Japan"
    click_on "Save"
    check_this_page page, "h2", "Comments" # let Capybara wait until the new category exists
    cu = category_url(id: Category.last.id, locale: :en)
    check_page page, cu, "h1", "Category"
    # 2nd try to create category 'mountain' as '山' in Japanese
    check_page page, new_category_url(locale: :ja), "h1", "カテゴリを追加", 190 # actual size is only 191 bytes
    fill_in "category_name_ja", with: "日本"
    click_on "保存"
    check_this_page page, nil, 'カテゴリ"日本" は既に存在する。'
  end

  # NICE cannot delete category created by another user
  # NICE cannot delete category with quotations

  # /categorys/new
  test "new category without login" do
    check_page page, new_category_url, "h1", /Access Denied .* 403/
  end

  test "edit own category" do
    do_login
    check_page page, edit_category_url(locale: :de, id: 1), "h1", "Kategorie bearbeiten"
    fill_in "category_name_de", with: "SchönererName"
    click_on "Speichern"
    check_this_page page, nil, /Kategorie .* wurde aktualisiert/
    check_page page, quotation_url(locale: :de, id: 1), nil, /Kategorien:.*SchönererName/
  end
  test "edit own category with empty category name fails" do
    do_login
    check_page page, edit_category_url(locale: :de, id: 1), "h1", "Kategorie bearbeiten"
    fill_in "category_name_de", with: ""
    click_on "Speichern"
    check_this_page page, nil, "Kategorie kann nicht leer sein"
  end
  test "update and translate new category" do
    do_login
    check_page page, new_category_url(locale: :en), "h1", "Create Category"
    fill_in "category_name_en", with: "Child"
    click_on "Save"
    check_this_page page, nil, 'The category "Child" has been created.'
    check_this_page page, nil, 'Niño'    # translation ES was working
    check_this_page page, nil, 'Дитинко' # translation UK was working
    click_on "Pencil"
    fill_in "category_name_es", with: "Abuelo" # me :)
    click_on "Save"
    check_this_page page, nil, 'The category "Child" has been updated.'
    check_this_page page, nil, "Abuelo"  # ES overwritten
    check_this_page page, nil, 'Дитинко' # UK still exist
    click_on "Pencil"
    click_on "Translate"
    check_this_page page, nil, 'The category "Child" has been updated.'
    check_this_page page, nil, 'Niño' # new translation ES was working
  end

  test "admin needed to list not public categories" do
    check_page page, categories_list_no_public_url, nil, "Not an Administrator!"
    do_login
    check_page page, categories_list_no_public_url, nil, "Not an Administrator!"
  end
  test "list not public categories" do
    do_login :admin_user, :admin_user_password
    check_this_page page, nil, "Hello admin_user, nice to have you here."
    check_page page, categories_list_no_public_url, "h1", "Not published Categories"
  end

  test "trailing slash" do
    check_page page, categories_url + "/", "h1", "Categories"
    assert_equal "Zitat-Service – Categories", page.title
    # redirected URL w/o slash
    assert_equal page.current_url, categories_url
  end

  test "pagination with trailing slash" do
    url = categories_url + "?page=2/"
    check_page page, url, "h1", "Categories"
    check_this_page page, nil, "Actions"
    # redirected URL w/o slash
    assert_equal page.current_url, url.chop
  end

  test "pagination not found" do
    url = categories_url + "?page=420000"
    check_page page, url, "h1", "400"
    # wrong URL have to be shown
    check_this_page page, nil, url
    check_page_source page, /href=".*quote\/issues/
  end
end
