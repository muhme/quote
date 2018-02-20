class AccountController < ApplicationController

  # say something nice, you goof!  something sweet.
  def index
    redirect_to(:action => 'signup') unless logged_in? || User.count > 0
  end

  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default(:controller => 'start', :action => 'list')
      flash[:notice] = "Hallo #{self.current_user.login.capitalize}, sch&ouml;n dass Du da bist."
    else
	  flash[:error] = "Die Anmeldung war nicht erfolgreich!"
    end
  end

  def signup

    # prevent elevation of privelege by faking parameter 'admin'
    if params[:user] and params[:user][:admin]
        logger.error "SECURITY admin was set" + params[:user].inspect
        params[:user][:admin] = 'false'
    end

    @user = User.new(params[:user])
    return unless request.post?
    @user.save!
    self.current_user = @user
    redirect_back_or_default(:controller => 'start', :action => 'list')
    flash[:notice] = "Dankesch&ouml;n f&uuml;r deine Anmeldung #{self.current_user.login.capitalize}. Viel Spass hier."
  rescue ActiveRecord::RecordInvalid
    render :action => 'signup'
  end
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "Du bist nun abgemeldet."
    redirect_back_or_default(:controller => 'start', :action => 'list')
  end
end
