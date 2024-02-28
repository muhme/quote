require "deepl"

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :current_user_session, :current_user, :access?, :has_non_public, :can_edit?
  before_action do
    bad_request? # check params[bad_request] which means BadRequest exception from Rack middleware
    bad_pagination? # check params[page] if existing
    set_locale # needed to set locale for each request
    if current_user && current_user.admin? && current_user.super_admin?
      Rack::MiniProfiler.authorize_request
    end
  end

  rescue_from ActionController::UnknownFormat do |exception|
    logger.error exception.message
    # render HTTP status 404
    redirect_to(controller: :static_pages, action: :not_found)
  end

  # include locale param in every URL and set locale
  def default_url_options
    { locale: I18n.locale }
  end

  private

  # set from param :locale, request HTTP_ACCEPT_LANGUAGE or use default :en
  def set_locale
    # already set or get very simple from browser or use default
    if params[:locale] && I18n.available_locales.include?(params[:locale].to_sym)
      logger.debug { "set_locale from params #{params[:locale]}" }
      I18n.locale = Mobility.locale = params[:locale]
    else
      hal = request.env["HTTP_ACCEPT_LANGUAGE"]
      extracted_locale = hal && hal.scan(/^[a-z]{2}/).first
      if extracted_locale && I18n.available_locales.include?(extracted_locale.to_sym)
        logger.debug { "set_locale from HTTP_ACCEPT_LANGUAGE=\"#{hal}\" #{extracted_locale}" }
        I18n.locale = Mobility.locale = extracted_locale
      else
        logger.debug { "set_locale default #{I18n.default_locale}" }
        I18n.locale = Mobility.locale = I18n.default_locale
      end
    end
  end

  # return true is the user is logged in and is an admin, or the owner
  # else returns false and redirect to forbidden
  #
  # action is :admin, :read, :update or :destroy
  def access?(action, obj)
    name = obj&.class&.name # default
    name = t("g.authors", count: 1) if name == "Author"
    name = t("g.quotes", count: 1) if name == "Quotation"
    name = t("g.categories", count: 1) if name == "Category"
    name = t("g.comment", count: 1) if name == "Comment"

    verb = t("g.have") # default
    verb = t("g.no_admin") if action == :admin
    verb = t("g.read") if action == :read
    verb = t("g.update") if action == :update
    verb = t("g.delete") if action == :destroy

    msg = t("g.no_right", name: name, id: obj&.id, msg: verb)

    if current_user and (current_user.admin or current_user.id == obj&.user_id)
      # own object or admin has read/write access
      return true
    end

    if action == :admin
      if current_user and current_user.admin
        return true
      end

      msg = t("g.no_admin")
    else
      if action == :read
        if obj&.public == true
          # public read access
          return true
        else
          # read access denied
          msg += " (#{t("g.not_publics", count: 1)})"
        end
      end
      if current_user
        if current_user.id != obj&.user_id
          # read/write other objects denied
          msg += " (#{t("g.not_own_entry")})"
        end
      else
        # not logged in read access denied
        msg += " (#{t("g.not_logged_in")})"
      end
    end

    flash[:error] = msg
    logger.debug { "access failed with #{msg}" }
    redirect_to forbidden_url
    return false
  end

  # check user is logged in or set error message, redirect to forbidden url and return false
  # this ends in HTTP 403 and the forbidden page with the msg message set as error
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
    current_user && (current_user.id == user_id || current_user.admin == true)
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

  # Are there any problems with params[:page] parameter given for pagination?
  # called 1st time as before_action
  # called 2nd time after pagination with known number of total_pages
  # in case of problems render HTTP status 400
  def bad_pagination?(total_pages = nil)
    if params and params[:page]
      page_number = Integer(params[:page])
      if ((page_number <= 0) or (total_pages and (page_number > total_pages)))
        raise t("g.bad_pagination.not_existing", page_number: page_number)
      end
    end
  rescue => e
    logger.info "bad pagination! url=#{request.original_url}"
    flash[:error] = e.message
    render "static_pages/bad_request", :status => :bad_request # 400
  end

  # error message from middleware Rack flagged as params[:bad_request]?
  def bad_request?
    if params and params[:bad_request].present?
      logger.error "bad request! \"#{params[:bad_request]}\""
      flash[:error] = CGI.unescape(params[:bad_request])
      render "static_pages/bad_request", :status => :bad_request # 400
    end
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

  # nice object log
  def nol(obj, print_array = false)
    return "nil" if obj.nil?
    return "\"#{obj}\"" if obj.is_a?(String)
    return "Integer #{obj}" if obj.is_a?(Integer)
    return "Array #{obj}" if obj.is_a?(Array) and print_array
    return "Array with #{obj.count} entries" if obj.is_a?(Array)

    return "#{obj.class}"
  end

  # own SQL sanitizer as sanitize_sql_like does nothing for comments (--) and apostroph (')
  # backslash and apostroph need hash to work, however
  def my_sql_sanitize(str)
    # logger.debug { "my_sql_sanitize(#{str})" }
    if str.present?
      str = str.gsub(/\\/, { "\\" => "\\\\" }) # backslash self
      str = str.gsub("--", "\\-\\-")           # SQL comment
      str = str.gsub("%", "\\%")               # wildcard in searching
      str = str.gsub("_", "\\_")               # single char
      str = str.gsub("\[", "\\\[")             # open bracket
      str = str.gsub("\]", "\\\]")             # close bracket
      str = str.gsub("\"", "\\\"")             # quotation marks
      str = str.gsub(/'/, { "'" => "\\'" })    # apostroph
    end
    # logger.debug { "my_sql_sanitize(#{str})" }
    return str
  end
end
