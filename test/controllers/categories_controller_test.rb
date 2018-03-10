require 'test_helper'

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category_one = categories(:one)
    @category_public_false = categories(:public_false)
    @category_without_quotes = categories(:without_quotes)
    activate_authlogic
  end
  
  test "setup" do
    assert_equal @category_one.quotation_ids.size, 1
    assert_equal @category_one.user_id, users(:first_user).id
    assert_not @category_public_false.public
    assert_equal @category_without_quotes.quotation_ids.size, 0
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
  end
  
  test "404 for not existing category" do
    id = rand 0..10000000000000
    get author_url id
    assert_response :redirect
    follow_redirect!
    assert_response :missing

    login :first_user
    get author_url id
    assert_response :redirect
    follow_redirect!
    assert_response :missing
  end 

  test "should show public category" do
    get category_url @category_one
    assert_response :success
    login :first_user
    get category_url @category_one
    assert_response :success
  end
  
  test "not public category" do
    get category_url @category_public_false
    assert_forbidden
    login :second_user
    get category_url @category_public_false
    assert_forbidden
    get '/logout'
    login :first_user
    get category_url @category_one
    assert_response :success
    get '/logout'
    login :admin_user
    get category_url @category_public_false
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
    post categories_url, params: { category: { category: "Game", description: "new category description" } }
    assert_forbidden
    assert_difference('Category.count') do
      login :first_user
      post categories_url, params: { category: { category: "Game", description: "new category description" } }
    end
    assert_redirected_to category_url(Category.last)
    category = Category.find_by_category 'Game'
    assert_not category.public
  end

  test "edit category" do
    get edit_category_url @category_one
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
    patch category_url(@category_one), params: { category: { description: "hu" } }
    assert_redirected_to category_url @category_one
    get '/logout'
    login :admin_user
    patch category_url(@category_one), params: { category: { description: "hu hu" } }
    assert_redirected_to category_url @category_one
    get '/logout' 
    patch category_url(@category_one), params: { category: { description: "hu hu hu" } }
    assert_forbidden
  end

  test "destroy category" do
    assert_no_difference 'Category.count' do
      delete category_url @category_without_quotes
    end
    assert_forbidden
    login :second_user
    assert_no_difference 'Category.count' do
      delete category_url @category_without_quotes
    end
    assert_forbidden
    get '/logout'
    login :first_user
    assert_difference('Category.count', -1) do
      delete category_url @category_without_quotes
    end
    assert_redirected_to categories_url
    get '/logout'
    login :admin_user
    assert_difference('Category.count', -1) do
      delete category_url @category_public_false
    end
    assert_redirected_to categories_url
  end
  
  test "list_no_public method" do
    get categories_list_no_public_url
    assert_redirected_to categories_url
    login :first_user
    get categories_list_no_public_url
    assert_redirected_to categories_url
    get '/logout'
    login :admin_user
    get categories_list_no_public_url
    assert_response :success
  end

end
