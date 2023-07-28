require 'test_helper'

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category_one = categories(:one)
    @category_public_false = categories(:public_false)
    @category_without_quotes = categories(:without_quotes)
  end
  
  test "setup" do
    assert_equal 2, @category_one.quotation_ids.size
    assert_equal users(:first_user).id, @category_one.user_id
    assert_not @category_public_false.public
    assert_equal 0, @category_without_quotes.quotation_ids.size
  end

  test "should get index" do
    get categories_url
    assert_response :success
    login :first_user
    get categories_url
    assert_response :success
  end

  test "list_by_letter method" do
    get "/categories/list_by_letter/p" # there is category public_category in fixtures
    assert_response :success
    get '/categories/list_by_letter/Q' # there is no author starting with letter Q in fixtures and it should render page, telling this
    assert_response :success
    get "/categories/list_by_letter/*"
    assert_response :success
    get "/en/categories/list_by_letter/X"
    assert_response :success
    get "/es/categories/list_by_letter/X"
    assert_response :success
    get "/ja/categories/list_by_letter/%E3%81%82" # あ
    assert_response :success
    get "/ja/categories/list_by_letter/%D0%99" # Й
    assert_response :success
    get '/categories/list_by_letter/'
    assert_response :redirect
    get '/categories/list_by_letter/%20'
    assert_response :success
  end
  
  test "404 for not existing category" do
    id = rand 0..10000000000000
    get category_url id: id
    assert_response :not_found

    login :first_user
    get author_url id
    assert_response :not_found
  end 

  test "should show public category" do
    get category_url id: @category_one
    assert_response :success
    login :first_user
    get category_url @category_one
    assert_response :success
  end
  
  test "not public category" do
    get category_url id: @category_public_false
    assert_response :success
    login :second_user
    get category_url id: @category_public_false
    assert_response :success
    get '/logout'
    login :first_user
    get category_url id: @category_one
    assert_response :success
    get '/logout'
    login :admin_user
    get category_url id: @category_public_false
    assert_response :success
  end
  
  test "should get new" do
    get new_category_url
    assert_forbidden
    login :first_user
    get new_category_url
    assert_response :success
  end

  test "should create category" do
    post categories_url(locale: :de), params: { category: { category_de: "Spiel" } }
    assert_forbidden
    assert_difference('Category.count') do
      login :first_user
      post categories_url(locale: :de), params: { category: { category_de: "Spiel" } }
    end
    assert_redirected_to category_url(id: Category.last.id, locale: 'de')
    category = Category.i18n.find_by(category: 'Spiel', locale: :de)
    assert_not category.public
  end

  test "edit category" do
    get edit_category_url id: @category_one
    assert_forbidden
    login :first_user
    get edit_category_url @category_one
    assert_response :success
    get '/logout'
    login :second_user
    get edit_category_url @category_one
    assert_forbidden
    get '/logout'
    login :admin_user
    get edit_category_url @category_one
    assert_response :success
  end

  test "update category" do
    login :first_user
    patch category_url(id: @category_one.id, locale: :en), params: { category: { category_en: "nice" } }
    assert_redirected_to category_url(id: @category_one.id, locale: :en)
    assert_equal Category.find(@category_one.id).category(locale: :en), "nice"
    get '/logout'
    login :admin_user
    patch category_url(id: @category_one.id, locale: :en), params: { category: { category_en: "nicer" } }
    assert_redirected_to category_url(id: @category_one.id, locale: :en)
    assert_equal Category.find(@category_one.id).category(locale: :en), "nicer"
    get '/logout' 
    patch category_url(id: @category_one.id, locale: :en), params: { category: { category_en: "nicest" } }
    assert_forbidden
    assert_equal Category.find(@category_one.id).category(locale: :en), "nicer"
  end
  
  test "return to edit if validation fails" do
    login :first_user
    patch category_url(id: @category_one.id, locale: :en), params: { category: { category_en: '' } }
    assert_response :unprocessable_entity # 422
    assert_match /1 fehler|1 error/i, @response.body
  end

  test "destroy category" do
    assert_no_difference 'Category.count' do
      delete category_url id: @category_without_quotes
    end
    assert_forbidden

    login :second_user
    assert_no_difference 'Category.count' do
      delete category_url id: @category_without_quotes
    end
    assert_forbidden
    get '/logout'

    login :first_user
    assert_difference('Category.count', -1) do
      delete category_url @category_without_quotes
    end
    assert_redirected_to categories_url
  end
  test "not able to delete category with quote" do
    login :first_user
    assert_no_difference('Category.count') do
      delete category_url @category_one
    end
    assert_response :unprocessable_entity # 422
    assert_equal category_url(@category_one), request.original_url
  end
  test "delete category as admin" do
    login :admin_user
    assert_difference('Category.count', -1) do
      delete category_url @category_without_quotes
    end
    assert_redirected_to categories_url
  end
  test "not able to delete category with comments" do
    login :first_user
    assert_no_difference 'Category.count'  do
      delete category_url (categories :with_one_comment)
    end
    assert_response :unprocessable_entity # 422
  end

  test "pagination" do
    # not a number
    get '/categories?page=X'
    assert_response :bad_request
    # have to be positive
    get '/categories?page=-1'
    assert_response :bad_request
    # there is no page zero
    get '/categories?page=0'
    assert_response :bad_request
    # 1st page
    get '/categories?page=1'
    assert_response :success
    # 2nd page
    get '/categories?page=2'
    assert_response :success
    # out of range
    get '/categories?page=42000000'
    assert_response :bad_request
  end

  test "pagination with letter" do
    # not a number
    get '/categories/list_by_letter/A?page=X'
    assert_response :bad_request
    # have to be positive
    get '/categories/list_by_letter/A?page=-1'
    assert_response :bad_request
    # there is no page zero
    get '/categories/list_by_letter/A?page=0'
    assert_response :bad_request
    # 1st page
    get '/categories/list_by_letter/A?page=1'
    assert_response :success
    # out of range
    get '/categories/list_by_letter/A?page=42000000'
    assert_response :bad_request
    # two tests (one before and one after) for list_no_public
    login :admin_user
    get '/categories/list_no_public?page=X'
    assert_response :bad_request
    get '/categories/list_no_public?page=42000000'
    assert_response :bad_request
  end

  test "list_no_public method" do
    get categories_list_no_public_url
    assert_forbidden
    login :first_user
    get categories_list_no_public_url
    assert_forbidden
    get '/logout'
    login :admin_user
    get categories_list_no_public_url
    assert_response :success
  end

  test "list duplicates" do
    get categories_list_duplicates_url(locale: :en)
    assert_forbidden
    login :first_user
    get categories_list_duplicates_url(locale: :en)
    assert_forbidden
    login :admin_user
    get categories_list_duplicates_url(locale: :en)
    assert_response :success
  end

  test "list categories by order" do
    get categories_url + "?order=categories"
    assert_response :success
  end

end
