class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :current_user_session, :current_user, :access?, :has_non_public, :can_edit?, :sql_quotations_for_category, :sql_quotations_for_author

  rescue_from ActionController::UnknownFormat do |exception|
    logger.error exception.message
    # render plain: '404 Not found', status: 404 
    redirect_to(controller: 'static_pages', action: 'not_found', original_url: request.original_url)
  end

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

    # give user context visible quotations for a category
    def sql_quotations_for_category(category_id)
      sql = "select q.* from quotations q, categories_quotations cq where cq.quotation_id = q.id and cq.category_id = '#{category_id}'"
      if current_user
        sql += " and q.public = 1 or q.user_id = #{current_user.id}" unless current_user.admin
      else
        sql += " and q.public = 1"
      end
      return sql
    end
    
    # give user context visible quotations for an author
    def sql_quotations_for_author(author_id)
      sql = "select * from quotations where author_id = '#{author_id}'"
      if current_user
        sql += " and public = 1 or user_id = #{current_user.id}" unless current_user.admin
      else
        sql += " and public = 1"
      end
      return sql
    end

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

    # if a user logged in with the same id oder as admin?
    def can_edit?(user_id)
      current_user && ( current_user.id == user_id || current_user.admin == true )
    end

    # checks if the Quotation, Author or Category has non public entries
    def has_non_public(thisClass)
      current_user && current_user.admin && thisClass.count_non_public > 0
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
