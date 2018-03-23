require 'test_helper'

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @first_user = users(:first_user)
  end
  
  # /password_resets/new
  test "new" do
    get new_password_reset_url
  end
  
  # /password_resets/1/edit
  test "edit" do
    get edit_password_reset_url @first_user
 end
 
#           password_resets POST   /password_resets(.:format)                       password_resets#create
#       new_password_reset GET    /password_resets/new(.:format)                   password_resets#new
#      edit_password_reset GET    /password_resets/:id/edit(.:format)              password_resets#edit
#           password_reset PATCH  /password_resets/:id(.:format)                   password_resets#update
#                          PUT    /password_resets/:id(.:format)                   password_resets#update
end