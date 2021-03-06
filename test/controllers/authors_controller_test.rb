require 'test_helper'

class AuthorsControllerTest < ActionDispatch::IntegrationTest
  
  setup do
    @author_one = authors(:one)
    @author_public_false = authors(:public_false)
    @author_without_quotes = authors(:without_quotes)
    activate_authlogic
  end
  
  test "should get index without login" do
    get authors_url
    assert_response :success
  end
  test "should get index with login" do
    login :first_user
    get authors_url
    assert_response :success
  end
  
  test "list by letter" do
    get '/authors/list_by_letter/B' # there is author Barbara in fixtures
    assert_response :success
    get '/authors/list_by_letter/Q' # there is no author starting with letter Q in fixtures and it should render page, telling this
    assert_response :success
    get '/authors/list_by_letter/*'
    assert_response :success
    get '/authors/list_by_letter/'
    assert_response :redirect
    get '/authors/list_by_letter/%20'
    assert_response :missing # 404
  end
  
  test "404 for not existing author without login" do
    get author_url(rand 0..10000000000000)
    assert_response :redirect
    follow_redirect!
    assert_response :missing
  end
  test "404 for not existing author with login" do
    login :first_user
    get author_url(rand 0..10000000000000)
  end 

  test "should show author without login" do
    get author_url @author_one
    assert_response :success
  end
  test "should show author with login" do
    login :first_user
    get author_url @author_one
    assert_response :success
  end
  test "fail to show not-public author with someone else login" do
    login :second_user
    get author_url @author_public_false
    assert_forbidden
  end
  test "should show not-public author to admin" do
    login :admin_user
    get author_url @author_public_false
    assert_response :success
  end

  test "fail new without login" do
    get new_author_url
    assert_forbidden
  end
  test "should get new" do
    login :first_user
    get new_author_url
    assert_response :success
  end

  test "fail to create author without login" do
    post authors_url, params: { author: { name: 'Johnson' } }
    assert_forbidden
  end
  test "should create author with login" do
    assert_difference 'Author.count' do
      login :first_user
      post authors_url, params: { author: { name: 'Johnson' } }
    end
    assert_redirected_to author_url(Author.last)
    author = Author.find_by_name 'Johnson'
    assert_not author.public
  end

  test "fail get edit without login" do
    get edit_author_url @author_one
    assert_forbidden
  end
  test "should get edit with login for own author" do
    login :first_user
    get edit_author_url @author_one
    assert_response :success
  end
  test "fail to get edit for others author entry for non-admin" do
    login :second_user
    get edit_author_url @author_one
    assert_forbidden
  end
  test "should get edit for others author entry for admin" do
    login :admin_user
    get edit_author_url @author_one
    assert_response :success
  end

  test "should update own author entry" do
    login :first_user
    patch author_url(@author_one), params: { author: { description: 'New Description', firstname: 'New Firstname', link: 'New Link', name: 'Luther' } }
    assert_redirected_to author_url(@author_one)
  end
  test "fail to edit other users author entry" do
    login :second_user
    patch author_url(@author_one), params: { author: { description: 'New Description', firstname: 'New Firstname', link: 'New Link', name: 'Luther' } }
    assert_forbidden
  end
  test "should update other users author entry as admin" do
    login :admin_user
    patch author_url(@author_one), params: { author: { description: 'New Description', firstname: 'New Firstname', link: 'New Link', name: 'Luther', public: true } }
    assert_redirected_to author_url @author_one
    author = Author.find_by_name 'Luther'
    assert author.public
  end
  test "return to edit if validation fails" do
    login :first_user
    patch author_url(@author_one), params: { author: { name: '' } }
    assert_response :success
    assert_match /1 fehler|1 error/i, @response.body
  end

  test "should destroy own author entry" do
    login :first_user
    assert_difference('Author.count', -1) do
      delete author_url @author_without_quotes
    end
    assert_redirected_to authors_url
  end
  test "fail to destroy author entry without login" do
    assert_no_difference 'Author.count' do
      delete author_url @author_without_quotes
    end
    assert_forbidden
  end
  test "fail to destroy other users author entry" do
    login :second_user
    assert_no_difference 'Author.count' do
      delete author_url @author_without_quotes
    end
    assert_forbidden
  end
  test "should destroy author entry as admin" do
    login :admin_user
    assert_difference('Author.count', -1) do
      delete author_url @author_without_quotes
    end
    assert_redirected_to authors_url
  end
  test "fail to destroy author entry used in quote" do
    login :admin_user
    assert_no_difference 'Author.count' do
      delete author_url @author_one
    end
    assert_redirected_to author_url(@author_one)
  end

  test "list_no_public method" do
    get authors_list_no_public_url
    assert_redirected_to authors_url
    login :first_user
    get authors_list_no_public_url
    assert_redirected_to authors_url
    get '/logout'
    login :admin_user
    get authors_list_no_public_url
    assert_response :success
  end

end