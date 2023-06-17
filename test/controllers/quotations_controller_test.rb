require 'test_helper'

class QuotationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @quotation_one = quotations(:one)
    @quotation_public_false = quotations(:public_false)
    activate_authlogic
  end
  
  test "setup" do
    assert       @quotation_one.public
    assert_equal @quotation_one.user_id, users(:first_user).id
    assert_not   @quotation_public_false.public
    assert_equal @quotation_public_false.user_id, users(:first_user).id
  end

  test "should get index" do
    get quotations_url
    assert_response :success
    login :first_user
    get quotations_url
    assert_response :success
  end
  
  test "list_by_category method" do
    get '/quotations/list_by_category/1'
    assert_response :success
    get '/quotations/list_by_category/42000000'
    assert_redirected_to root_url
  end
  
  test "list_by_user method" do
    get '/quotations/list_by_user/1'
    assert_response :success
    get '/quotations/list_by_user/jhrefoqg'
    assert_redirected_to root_url
  end

  test "list_by_author" do
    get '/quotations/list_by_author/1'
    assert_response :success
    get '/quotations/list_by_author/x'
    assert_redirected_to root_url
  end
  
  test "404 for not existing quote" do
    id = rand 0..10000000000000
    get quotation_url id: id
    assert_response :not_found

    login :first_user
    get quotation_url id
    assert_response :not_found

  end
  
  test "should show public quote" do
    get quotation_url id: @quotation_one
    assert_response :success
    login :first_user
    get quotation_url @quotation_one
    assert_response :success
  end

  test "not public quote" do
    get quotation_url id: @quotation_public_false
    assert_response :success
    login :second_user
    get quotation_url @quotation_public_false
    assert_response :success
    get '/logout'
    login :first_user
    get quotation_url @quotation_public_false
    assert_response :success # quote is public false, but created by first user
    get quotation_url @quotation_one
    assert_response :success
    get '/logout'
    login :admin_user
    get quotation_url @quotation_public_false
    assert_response :success
  end
  
  test "should get new" do
    get new_quotation_url
    assert_forbidden
    login :first_user
    get new_quotation_url
    assert_response :success
  end

  test "should create quotation" do
    post quotations_url, params: { commit: "Speichern", quotation: { quotation: "Yes we can." } }
    assert_forbidden
    assert_difference('Quotation.count') do
      login :first_user
      post quotations_url, params: { commit: "Speichern", quotation: { quotation: "Yes we can.", author_id: 0 } }
    end
    assert_redirected_to quotation_url(Quotation.last)
    quotation = Quotation.find_by_quotation 'Yes we can.'
    assert_not quotation.public
  end

  test "should get edit" do
    get edit_quotation_url id: @quotation_one
    assert_forbidden
    login :first_user
    get edit_quotation_url @quotation_one
    assert_response :success
    get '/logout'
    login :second_user
    get edit_quotation_url @quotation_one
    assert_forbidden
    get '/logout'
    login :admin_user
    get edit_quotation_url @quotation_one
    assert_response :success
  end

  test "should update quotation" do
    login :first_user
    patch quotation_url(@quotation_one), params: { commit: "Speichern", quotation: { quotation: 'The early bird catches the worm' } }
    assert_redirected_to quotation_url @quotation_one
    get '/logout'
    login :admin_user
    patch quotation_url(@quotation_one), params: { commit: "Speichern", quotation: { quotation: 'The early bird catches the worm!' } }
    assert_redirected_to quotation_url @quotation_one
    get '/logout'
    patch quotation_url(@quotation_one), params: { commit: "Speichern", quotation: { quotation: 'The early bird catches the worm!!!' } }
    assert_forbidden
    login :first_user
    patch quotation_url(@quotation_one), params: { commit: "Speichern", quotation: { quotation: '' } }
    assert_response :unprocessable_entity # 422
    assert_match /1 fehler|1 error/i, @response.body
  end

  test "destroy quotation" do
    assert_no_difference 'Quotation.count' do
      delete quotation_url id: @quotation_one
    end
    assert_forbidden
    login :second_user
    assert_no_difference 'Quotation.count' do
      delete quotation_url @quotation_one
    end
    assert_forbidden
    get '/logout'
    login :first_user
    assert_difference('Quotation.count', -1) do
      delete quotation_url @quotation_one
    end
    assert_redirected_to quotations_url
    get '/logout'
    login :admin_user
    assert_difference('Quotation.count', -1) do
      delete quotation_url @quotation_public_false
    end
    assert_redirected_to quotations_url
  end

  test "list_no_public method" do
    get quotations_list_no_public_url
    assert_redirected_to forbidden_url
    login :first_user
    get quotations_list_no_public_url
    assert_redirected_to forbidden_url
    get '/logout'
    login :admin_user
    get quotations_list_no_public_url
    assert_response :success
  end

  test "pagination" do
    # not a number
    get '/quotations?page=X'
    assert_response :bad_request
    # have to be positive
    get '/quotations?page=-1'
    assert_response :bad_request
    # there is no page zero
    get '/quotations?page=0'
    assert_response :bad_request
    # 1st page
    get '/quotations?page=1'
    assert_response :success
    # 2nd page
    get '/quotations?page=2'
    assert_response :success
    # out of range
    get '/quotations?page=42000000'
    assert_response :bad_request
    # together with (not existing) pattern, 1st page is always existing
    get '/quotations?page=1&pattern=eruhf2ghu'
    assert_response :success
    # (not existing) pattern out of range
    get '/quotations?page=2&pattern=wefgrifgi24i2'
    assert_response :bad_request
    # repeat tests for other paginate_by_sql with two tests each (one before and one after)
    get '/quotations/list_by_user/first_user?page=X'
    assert_response :bad_request
    get '/quotations/list_by_user/1?page=42000000'
    assert_response :bad_request
    get '/quotations/list_by_author/1?page=X'
    assert_response :bad_request
    get '/quotations/list_by_author/1?page=42000000'
    assert_response :bad_request
    get '/quotations/list_by_category/1?page=X'
    assert_response :bad_request
    get '/quotations/list_by_category/1?page=42000000'
    assert_response :bad_request
    login :admin_user
    get '/quotations/list_no_public?page=X'
    assert_response :bad_request
    get '/quotations/list_no_public?page=42000000'
    assert_response :bad_request
  end
  
end
