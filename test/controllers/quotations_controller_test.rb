require 'test_helper'

class QuotationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @quotation = quotations(:one)
  end

  test "should get index" do
    get quotations_url
    assert_response :success
  end

  test "should get new" do
    get new_quotation_url
    assert_response :success
  end

# TODO
#  test "should create quotation" do
#    assert_difference('Quotation.count') do
#      post quotations_url, params: { quotation: { quotation: "new" } }
#    end
#
#    assert_redirected_to quotation_url(Quotation.last)
#  end

  test "should show quotation" do
    get quotation_url(@quotation)
    assert_response :success
  end

  test "should get edit" do
    get edit_quotation_url(@quotation)
    assert_response :success
  end

  test "should update quotation" do
    @user = users(:first_user)
    @author = authors(:one)
    patch quotation_url(@quotation), params: { quotation: { quotation: @quotation.quotation, user_id: @user.id, author_id: @author.id } }
    assert_redirected_to quotation_url(@quotation)
  end

  test "should destroy quotation" do
    assert_difference('Quotation.count', -1) do
      delete quotation_url(@quotation)
    end

    assert_redirected_to quotations_url
  end
end
