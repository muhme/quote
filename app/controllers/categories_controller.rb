class CategoriesController < ApplicationController
  before_action :set_category, only: [:show, :edit, :update, :destroy]
  before_action only: [:index, :list_by_letter, :list_no_public] do
    check_pagination(params[:page], nil)
  end

  # GET /categories
  def index
    sql =  "select distinct * from categories c"
    sql += " where c.public = 1" if not current_user or current_user.admin != true
    sql += " or c.user_id = #{current_user.id}" if current_user and current_user.admin != true
    sql += params[:order] == 'categories' ?
      # by category name alphabeticaly
      ' order by c.category' :
      # by the number of quotations that the categories have
      ' order by (select count(*) from categories_quotations cq, quotations q where cq.quotation_id = q.id and cq.category_id = c.id) desc'

    @categories = Category.paginate_by_sql(sql, page: params[:page], :per_page => 10)
    # check pagination second time with number of pages
    check_pagination(params[:page], @categories.total_pages)
  end

  # GET /categories/1
  def show
    return unless access?(@category, :read)
  end

  # GET /categories/new
  def new
    return unless logged_in? "Anmeldung fehlt, um eine neue Kategorie anzulegen!"
    @category = Category.new
    @category.user_id = current_user.id
  end

  # GET /categories/1/edit only for admin or own user
  def edit
    return unless access?(@category, :update)
  end

  # POST /categories
  def create
    return unless logged_in? "Anmeldung fehlt, um eine neue Kategorie anzulegen!"
    @category = Category.new(category_params)
    @category.user_id = current_user.id

    if @category.save
      redirect_to @category, notice: "Die Kategorie \"#{@category.category}\" wurde angelegt."
    else
      render :new, status: :unprocessable_entity
    end

    rescue Exception => exc
      logger.error "create category failed: #{exc.message}"
      flash[:error] = "Das Anlegen des Autors \"#{@category.category}\" ist gescheitert! (#{exc.message})"
  end

  # PATCH/PUT /categories/1
  def update
    return unless access?(@category, :update)

    if @category.update category_params
      redirect_to @category, notice: "Kategorie \"#{@category.category}\" wurde aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /categories/1
  def destroy
    return unless access?(@category, :destroy)
    n = @category.quotation_ids.size
    if n > 0
      flash[:error] = "Die Kategorie \"#{@category.category}\" hat #{n} Zitate und kann nicht gelöscht werden."
      redirect_to :action => 'show', :id => @category.id
    else
      if @category.destroy
        flash[:notice] = "Kategorie \"#{@category.category}\" wurde gelöscht."
      end
      redirect_to categories_url
    end
  end
  
  # get category list for a letter or all-no-letters
  # NICE only showing public or own entries to be extended like in index
  def list_by_letter
    letter = params[:letter]
    if letter == "*"
      sql = "select * from categories where category NOT REGEXP '^[A-Z].*'"
    elsif letter =~ /[A-Za-z*]/
      sql = "select * from categories where category like ?"
    else # not reachable, because route restrictions already forbid it - but, just in case
      flash[:error] = "Buchstabe fehlt!"
      redirect_to :action => 'list'
      return
    end
    sql += ' order by category'
    @categories = Category.paginate_by_sql [sql, "#{letter.first}%"], :page=>params[:page], :per_page=>10
    # check pagination second time with number of pages
    check_pagination(params[:page], @categories.total_pages)
  end

  # for admins list all not public categories
  def list_no_public
    if !current_user or current_user.admin == false
      flash[:error] = "Kein Administrator!"
      redirect_to categories_url
      return false
    end
    @categories = Category.paginate_by_sql 'select * from categories where public = 0', :page=>params[:page], :per_page=>10
    # check pagination second time with number of pages
    check_pagination(params[:page], @categories.total_pages)
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_category
      @category = Category.find(params[:id])
      rescue
        flash[:error] = "Es gibt keine Kategorie mit der ID \"#{params[:id]}\"."
        redirect_to not_found_url
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def category_params
      params.require(:category).permit(:category, :description, :public)
    end
end
