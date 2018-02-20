# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time

  before_filter :check_www_subdomain

  # Redirects the HTTP request if the request isn't comming from subdomain www.
  # The redirect uses HTTP status code 301 (Moved Permanently) and keeps protocol, host name, port and path.
  # e.g redirects http://zitat-service.de to http://www.zitat-service.de
  def check_www_subdomain
    if !/^www/.match(request.host) and request.host != '127.0.0.1'
      redirect_to request.protocol + "www." + request.host_with_port + request.request_uri,
        :status=>:moved_permanently
    end
  end

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'aa4ed76eef6d5af053ed3e769f5d0c99'

    # Pick a unique cookie name to distinguish our session data from others'
    session :session_key => '_quote_session_id'

    # for acts as authenticated
    include AuthenticatedSystem
	# "remember me" functionality
	before_filter :login_from_cookie

    # return true is the user is logged in and is an admin, or the owner
    # else returns false and redirect to list the :id
    # aquivalent to applicationHelper.can_edit? for the views

    # action :read, :update or :destroy
    def access?(obj, action)

        msg = "haben"        # default
        msg = "lesen"        if action == :read
        msg = "&auml;ndern"  if action == :update
        msg = "l&ouml;schen" if action == :destroy
        msg = "Kein Recht den Eintrag #{obj.id} zu #{msg}!"

        if logged_in? and (self.current_user.admin or self.current_user.id == obj.user_id)
            # write access
            return true
        else
            if action == :read
                if obj.public == true
                    # public read access
                    return true
                else
                    # read access denied
                    msg += " (Nicht &ouml;ffentlich)"
                end
            end
            if logged_in?
                if self.current_user.id == obj.user_id
                    # own-object read/write access
                    return true
                else
                    # read/write other objects denied
                    msg += " (Nicht der eigene Eintrag)"
                end
            else
                # not logged in read access denied
                msg += " (Nicht angemeldet)"
            end
        end

        flash[:error] = msg;
        redirect_to :action => 'list'
        return false
    end

	def rescue_action_in_public(exception)
	  case exception
	    when ActiveRecord::RecordNotFound, ActionController::UnknownAction
	      redirect_to :controller=>"start", :action=>"not_found"
		else
	      redirect_to :controller=>"start", :action=>"error_found"
		end
	end

    # prevent elevation of privelege by faking parameter 'public' for not-admins
    # as side effect the method sets public=false for updates from non-admins
    #
    def prevent_faking_parameter_public(params)

      if ! logged_in? or ! self.current_user.admin
        if params['public']
          logger.error "SECURITY public was true, but user \"" + user_name() + "\" is no admin " + params.inspect
        end
        params['public'] = "false"
      end
      return params
    end

    def user_name
      (logged_in? and self.current_user) ?
          self.current_user.login : "unknown"
    end



#  def local_request?
#    false
#  end

	def method_missing(method)
      redirect_to :controller=>"start", :action=>"not_found", :id=>method
	end

end
