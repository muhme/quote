class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :current_user_session, :current_user, :access?, :has_non_public, :can_edit?

  protected

    def handle_unverified_request
      # raise an exception
      fail ActionController::InvalidAuthenticityToken
      # or destroy session, redirect
      if current_user_session
        current_user_session.destroy
      end
      redirect_to root_url
    end
  
  private
  
    # return true is the user is logged in and is an admin, or the owner
    # else returns false and redirect to forbidden
    #
    # action is :read, :update or :destroy
    def access?(obj, action)

      name = obj.class.name # default
      name = "Autor"        if name == "Author"
      name = "Zitat"        if name == "Quotation"
      name = "Kategorie"    if name == "Category"
    
      msg = "haben"   # default
      msg = "lesen"   if action == :read
      msg = "ändern"  if action == :update
      msg = "löschen" if action == :destroy
      msg = "Kein Recht #{name} #{obj.id} zu #{msg}!"
      
      if current_user and (current_user.admin or current_user.id == obj.user_id)
        # write access
        return true
      else
        if action == :read
          if obj.public == true
            # public read access
            return true
          else
            # read access denied
            msg += " (Nicht öffentlich)"
          end
        end
        if current_user
          if current_user.id == obj.user_id
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
      redirect_to forbidden_url
      return false
    end

    # TODO
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
