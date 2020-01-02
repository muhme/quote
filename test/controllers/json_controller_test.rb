require 'test_helper'

class JsonControllerTest < ActionDispatch::IntegrationTest

  
  test "ActionController::UnknownFormat exception" do
    get "/", :as => :json
    assert_response :redirect
  end

end
