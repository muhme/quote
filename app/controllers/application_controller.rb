class ApplicationController < ActionController::Base
# TODO  filter_parameter_logging :password
  protect_from_forgery with: :exception
  helper_method :current_user_session, :current_user, :access?, :logged_in?, :has_non_public, :can_edit?



  protected

# TODO
#    # CSRF (Cross Site Request Forgery) protection for authlogic
#    def handle_unverified_request
#      # raise an exception
#      fail ActionController::InvalidAuthenticityToken
#      # or destroy session, redirect
#      if current_user_session
#        current_user_session.destroy
#      end
#      redirect_to root_url
#    end
  
  
  private

    # TODO
    def access?
      true
    end
    def logged_in?
      true
    end
    def has_non_public(o)
      return nil
    end
    def can_edit?(o)
      return true
    end
  
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.user
    end
  
end
