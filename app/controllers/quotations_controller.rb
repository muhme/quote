class QuotationsController < ApplicationController
  include ActionView::Helpers::TextHelper # for truncate()
  before_action :set_quotation, only: [:show, :edit, :update, :destroy]
  before_action only: [:index, :list_by_user, :list_by_author, :list_by_category, :list_no_public] do
    check_pagination(params[:page], nil)
  end

  # GET /quotations
  # GET /quotations?pattern=berlin
  # GET /quotations?page=42
  # get all public for not logged in users and own entries for logged in users and all entries for admins
  def index
    pattern = params[:pattern].blank? ? "%" : params[:pattern]
    sql = "select distinct * from quotations where quotation like '%" + pattern + "%' "
    if current_user
      sql += " and public = 1 or user_id = #{current_user.id}" unless current_user.admin
    else
      sql += " and public = 1"
    end
    sql += " order by id desc"

    @quotations = Quotation.paginate_by_sql(sql, page: params[:page], :per_page => 5)
    # check pagination second time with number of pages
    check_pagination(params[:page], @quotations.total_pages)

    # give hint on first page if no other notice exist
    if ! flash[:notice] and ( ! params[:page] or params[:page].to_i == 1 )
      flash.now[:notice] = 'Die Zitate sind danach sortiert, wann sie eingestellt wurden. Die zuletzt eingestellten Zitate stehen oben.' 
    end
  end

  # GET /quotations/1
  def show
    return unless access?(@quotation, :read)
  end

  # GET /quotations/new
  def new
    return unless logged_in? "Anmeldung fehlt, um ein neues Zitat anzulegen!"
    @quotation = Quotation.new(:user_id => current_user.id)
  end

  # GET /quotations/1/edit
  def edit
    return unless access?(@quotation, :update)
  end

  # GET quotations/author_selected/author_id
  # called from search author result list as a click on a link
  def author_selected
    return unless logged_in? "Anmeldung fehlt, um ein neues Zitat anzulegen!"
    double_turbo([], params[:author_id])
  end

  # POST /quotations
  def create
    return unless logged_in? "Anmeldung fehlt, um ein neues Zitat anzulegen!"

    @authors = Author.filter_by_name_firstname_description(params[:author])
    logger.debug { "found #{@authors.count} authors for \"#{params[:author]}\"" }

    if params[:commit]
      @quotation = Quotation.new(quotation_params.except(:author))
      @quotation.user_id = current_user.id
      @quotation.author_id = 0 unless @quotation.author_id # empty author field is an unknown author
      logger.debug { "saving #{@quotation.inspect}" }
      if @quotation.save
        hint = "Dankeschön, das #{@quotation.id}. Zitat wurde angelegt."
        hint << " Als Autor wurde „#{Author.find(@quotation.author_id).name}” verwendet." if @authors.count != 1
        return redirect_to @quotation, notice: hint
      else
        render :new, status: :unprocessable_entity
      end
    else
      if @authors.count == 1
        double_turbo([], @authors.first.id)
      else
        render turbo_stream: turbo_stream.update("search_author_results",
          partial: "quotations/search_author_results", locals: {authors: @authors})
      end
    end
    
    rescue Exception => exc
      logger.error "create quotation failed: #{exc.message}, backtrace:"
      exc.backtrace.each { |n| logger.error "   #{n}" }
      flash[:error] = "Das Anlegen des Zitates ist gescheitert! (#{exc.message})"
      render :new, status: :unprocessable_entity
  end

  # PATCH/PUT /quotations/1
  def update
    return unless access?(@quotation, :update)

    @authors = Author.filter_by_name_firstname_description(params[:author])
    logger.debug { "found #{@authors.count} authors for \"#{params[:author]}\"" }

    if params[:commit]
      logger.debug { "update quotation #{@quotation.inspect}" }
      if @quotation.update(quotation_params)
        hint = 'Das Zitat wurde aktualisiert.'
        hint << " Der Autor „#{Author.find(@quotation.author_id).name}” wurde nicht geändert." if @authors.count != 1
        return redirect_to @quotation, notice: hint
      else
        render :edit, status: :unprocessable_entity
      end
    else
      if @authors.count == 1
        double_turbo([], @authors.first.id)
      else
        render turbo_stream: turbo_stream.update("search_author_results",
          partial: "quotations/search_author_results", locals: {authors: @authors})
      end
    end
  end

  # DELETE /quotations/1
  def destroy
    return unless access?(@quotation, :destroy)
    if @quotation.destroy
      flash[:notice] = "Das Zitat \"" + truncate(@quotation.quotation, length: 20) + "\" wurde gelöscht."
    end
    return redirect_to quotations_url
  end  

  # list quotations created by a user
  def list_by_user
    unless User.exists?(:login => params[:user])
      flash[:error] = "Kann Benutzer \"#{params[:user]}\" nicht finden!"
      return redirect_to root_url
    end
    
    sql = ["select distinct q.* from quotations q, users u where q.user_id = u.id and u.login = ? order by q.created_at desc", params[:user]]
    @quotations = Quotation.paginate_by_sql sql, :page=>params[:page], :per_page=>5
    # check pagination second time with number of pages
    check_pagination(params[:page], @quotations.total_pages)
  end
  
  def list_by_category
    unless Category.exists? params[:category]
      flash[:error] = "Kann Kategorie \"#{params[:category]}\" nicht finden!"
      return redirect_to root_url
    end
    @category = Category.find params[:category]
    @quotations = Quotation.paginate_by_sql sql_quotations_for_category(@category.id), :page=>params[:page], :per_page=>5
    # check pagination second time with number of pages
    check_pagination(params[:page], @quotations.total_pages)
  end
  
  # select * from `quotations` where q.public = 1 and author_id = ?
  def list_by_author
    unless Author.exists? params[:author]
      flash[:error] = "Kann den Autor \"#{params[:author]}\" nicht finden!"
      return redirect_to root_url
    end
    @author = Author.find params[:author]
    @quotations = Quotation.paginate_by_sql sql_quotations_for_author(@author.id), :page=>params[:page], :per_page=>5
    # check pagination second time with number of pages
    check_pagination(params[:page], @quotations.total_pages)
  end
  
  # for admins list all not public categories
  def list_no_public
    if !current_user or current_user.admin == false
      flash[:error] = "Kein Administrator!"
     return redirect_to forbidden_url
    end
    @quotations = Quotation.paginate_by_sql 'select * from quotations where public = 0', :page=>params[:page], :per_page=>5
    # check pagination second time with number of pages
    check_pagination(params[:page], @quotations.total_pages)
  end

  private

    def set_quotation
      @quotation = Quotation.find(params[:id])
      rescue
        flash[:error] = "Es gibt kein Zitat mit der ID \"#{params[:id]}\"."
        return redirect_to not_found_url
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def quotation_params
      params.require(:quotation).permit(:author_id, :quotation, :source, :source_link, :public, :category, :pattern, :category_ids => [])
    end

    # update partial search author field and update partial search author result list together
    #   authors - array or empty array to make the search author result list disappear
    #   author_id - fill author field with given
    def double_turbo(authors, author_id)
      turbo_stream_add_update("search_author_results", partial: "quotations/search_author_results", locals: {authors: authors})
      turbo_stream_add_update("search_author", partial: "quotations/search_author", locals: {author_id: author_id })
      render turbo_stream: turbo_stream_do_actions
    end

end
