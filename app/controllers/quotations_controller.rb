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
    @quotation = Quotation.new
    @quotation.author_id = 0 # defaults to author "unknown"
    if current_user
      @quotation.user_id = current_user.id
    else
      flash[:error] = "Anmeldung fehlt, um ein neues Zitat anzulegen!"
      redirect_to forbidden_url 
    end
  end

  # GET /quotations/1/edit
  def edit
    return unless access?(@quotation, :update)
    # initialize search_author with quotes author_id
    session[:author_id] = @quotation.author_id
  end

  # quotations author autocompletion field in creating or editing a quotation is implemented as a separate form
  # status of selected author for quotation form actions is hold with two variables:
  #   session[:author_id] - selected author id (by click on the link or if only one author matches the search pattern)
  #   [:quotation][:modus] either "new" (for create) or "edit" for update
  # Do you see a not that complicated implementaion? please let me know :)

  # POST /quotations/search_author
  # Parameters {"authenticity_token"=>"[FILTERED]", "search_author"=>{"author"=>"sch"}, "quotation"=>{"modus"=>"new"}}
  def search_author
    searching = params[:search_author][:author]
    modus = params[:quotation][:modus]
    @authors = []
    @authors = Author.filter_by_name(searching) if searching.present?
    logger.debug { "found #{@authors.count} authors for \"#{searching}\"" }
    if @authors.count == 1
      logger.debug { "set session[:author_id] to #{@authors.first.id}" }
      session[:author_id] = @authors.first.id
    else
      session.delete(:author_id)
    end
    render turbo_stream: turbo_stream.update("search_author_results", partial: "quotations/search_author_results", locals: {authors: @authors, modus: modus })
  end

  # GET quotations/author_selected/id
  def author_selected
    unless current_user
      flash[:error] = "Anmeldung fehlt, um ein neues Zitat anzulegen!"
      redirect_to forbidden_url
      return
    end

    logger.debug { "set session[:author_id] to #{params[:id]}" }
    session[:author_id] = params[:id]
    redirect_back_or_to({ action: params[:modus]})
  end

  # POST /quotations
  def create
    unless current_user
      flash[:error] = "Anmeldung fehlt, um ein neues Zitat anzulegen!"
      redirect_to forbidden_url
      return
    end

    @quotation = Quotation.new(quotation_params.except(:search_author))
    @quotation.user_id = current_user.id

    @quotation.author_id = session[:author_id] ? session[:author_id] : 0
    logger.debug { "saving #{@quotation.inspect}" }
    if @quotation.save
      session.delete(:author_id) # eat selected author
      redirect_to @quotation, notice: "Dankeschön, das #{@quotation.id}. Zitat wurde angelegt."
    else
      render :new, status: :unprocessable_entity
    end
    
    rescue Exception => exc
      logger.error "create quotation failed: #{exc.message}"
      flash[:error] = "Das Anlegen des Zitates ist gescheitert! (#{exc.message})"
      render :new, status: :unprocessable_entity
  end

  # PATCH/PUT /quotations/1
  def update
    return unless access?(@quotation, :update)

    @quotation.author_id = session[:author_id] ? session[:author_id] : 0
    logger.debug { "update quotation #{@quotation.inspect}" }
    if @quotation.update(quotation_params.except(:search_author))
      session.delete(:author_id) # eat selected author
      redirect_to @quotation, notice: 'Das Zitat wurde aktualisiert.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /quotations/1
  def destroy
    return unless access?(@quotation, :destroy)
    if @quotation.destroy
      flash[:notice] = "Das Zitat \"" + truncate(@quotation.quotation, length: 20) + "\" wurde gelöscht."
    end
    redirect_to quotations_url
  end  

  # list quotations created by a user
  def list_by_user
    unless User.exists?(:login => params[:user])
      flash[:error] = "Kann Benutzer \"#{params[:user]}\" nicht finden!"
      redirect_to root_url
      return false
    end
    
    sql = ["select distinct q.* from quotations q, users u where q.user_id = u.id and u.login = ? order by q.created_at desc", params[:user]]
    @quotations = Quotation.paginate_by_sql sql, :page=>params[:page], :per_page=>5
    # check pagination second time with number of pages
    check_pagination(params[:page], @quotations.total_pages)
  end
  
  def list_by_category
    unless Category.exists? params[:category]
      flash[:error] = "Kann Kategory \"#{params[:category]}\" nicht finden!"
      redirect_to root_url
      return false
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
      redirect_to root_url
      return false
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
     redirect_to quotations_url
     return false
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
        redirect_to not_found_url
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def quotation_params
      params.require(:quotation).permit(:search_author, :quotation, :source, :source_link, :public, :category, :pattern, :category_ids => [])
    end  
end
