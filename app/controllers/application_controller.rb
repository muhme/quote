class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :current_user_session, :current_user, :access?, :has_non_public, :can_edit?, :sql_quotations_for_category, :sql_quotations_for_author

  rescue_from ActionController::UnknownFormat do |exception|
    logger.error exception.message
    # render plain: '404 Not found', status: 404 
    redirect_to(controller: 'static_pages', action: 'not_found', original_url: request.original_url)
  end
  
  private

    # give user context visible quotations for a category
    def sql_quotations_for_category(category_id)
      # one sample: select distinct q.* from quotations q where q.public = 1 and q.id in (select cq.quotation_id from categories_quotations cq where cq.category_id = '487'); 
      sql = "select distinct q.* from quotations q where"
      if current_user
        sql += " ( q.public = 1 or q.user_id = '#{current_user.id}' ) and" unless current_user.admin
      else
        sql += " q.public = 1 and"
      end
      return sql + " q.id in (select cq.quotation_id from categories_quotations cq where cq.category_id = '#{category_id}')"
    end
    
    # give user context visible quotations for an author
    def sql_quotations_for_author(author_id)
      sql = "select * from quotations where author_id = '#{author_id}'"
      if current_user
        sql += " and ( public = 1 or user_id = #{current_user.id} ) " unless current_user.admin
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
        # own object or admin has read/write access
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
          if current_user.id != obj.user_id
            # read/write other objects denied
            msg += " (Nicht der eigene Eintrag)"
          end
        else
          # not logged in read access denied
          msg += " (Nicht angemeldet)"
        end
      end
      
      flash[:error] = msg;
      logger.debug { "access failed with #{msg}" }
      redirect_to forbidden_url
      return false
    end

    # check user is logged in or set error message, redirect to forbidden url and return false
    def logged_in?(msg)
      if current_user
        return true 
      else
        flash[:error] = msg
        redirect_to forbidden_url
        return false
      end 
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

    # Are there any problems with page parameter given for pagination?
    # called 1st time as before_action
    # called 2nd time after pagination with total_pages set
    # in case of problems renders status 404 and useful page
    def check_pagination(page, total_pages)
      if page
        page_number = Integer(page) 
        raise "page >= 0" if page_number <= 0
        raise "page > #{total_pages}" if total_pages and page_number > total_pages
      end
    rescue Exception => exc
      flash[:error] = "#{exc.message}"
      @original_url = request.original_url
      render "static_pages/not_found", :status => 404
    end
   
    # collect Turbo Streams updates ...
    #   key - turbo-stream target
    #   component - partial with locals
    # from https://github.com/hotwired/turbo-rails/issues/77
    def turbo_stream_add_update(key, component)
      @turbo_stream_actions ||= []
      @turbo_stream_actions << turbo_stream.update(key, view_context.render(component))
    end
    # ... and run them with one rendering
    def turbo_stream_do_actions()
      @turbo_stream_actions
    end
end
