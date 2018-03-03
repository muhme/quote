require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'authlogic/test_case'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # do an authlogic login, usually with user entry from test fixtures
  def login(username)
    post user_sessions_url, :params => { :user_session => { :login => username, :password => (username.to_s + "_password") } }
  end
  
  # doing first a redirect to /forbidden and gives second an 403 from there
  def assert_forbidden
    assert_response :redirect
    follow_redirect!
    assert_response :forbidden
  end

  # doing first a redirect to /not_found and gices second an 404 from there  
  def assert_missing
    assert_response :redirect
    follow_redirect!
    assert_response :missing
  end

end