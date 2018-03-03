class CategoriesController < ApplicationController
  before_action :set_category, only: [:show, :edit, :update, :destroy]

  # GET /categories
  # GET /categories.json
  def index
    sql = 'select * from categories c'
    sql += ' where  c.public = 1' if false # TODO not logged_in? or current_user.admin != true
    sql += ' or c.user_id = ?' if false # TODO (logged_in? and current_user.admin != true)
    sql += params[:order] == 'categories' ?
      # by category name alphabeticaly
      ' order by c.category' :
      # by the number of quotations that the categories have
      ' order by (select count(*) from categories_quotations cq, quotations q where cq.quotation_id = q.id and cq.category_id = c.id) desc'
    @categories = Category.paginate_by_sql(sql, page: params[:page], :per_page => 10)
  end

  # GET /categories/1
  # GET /categories/1.json
  def show
    @category = Category.find(params[:id])
    return unless access?(@category, :read)
  end

  # GET /categories/new
  def new
    @category = Category.new
    @category.user_id = User.first.id # TODO hack, replace by actual user id
  end

  # GET /categories/1/edit
  def edit
    @category = Category.find(params[:id])
    return unless access?(@category, :update) # TODO
  end

  # POST /categories
  # POST /categories.json
  def create
    @category = Category.new(category_params)
    @category.user_id = User.first.id  # TODO set actual user id

    respond_to do |format|
      if @category.save
        format.html { redirect_to @category, notice: "Die Kategorie \"#{@category.category}\" wurde angelegt." }
        format.json { render :show, status: :created, location: @category }
      else
        format.html { render :new }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /categories/1
  # PATCH/PUT /categories/1.json
  def update
    respond_to do |format|
      if @category.update(category_params)
        format.html { redirect_to @category, notice: 'Category was successfully updated.' }
        format.json { render :show, status: :ok, location: @category }
      else
        format.html { render :edit }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /categories/1
  # DELETE /categories/1.json
  def destroy
    name = @category.category
    @category.destroy
    respond_to do |format|
      format.html { redirect_to categories_url, notice: "Kategorie \"#{name}\" wurde gelöscht." }
      format.json { head :no_content }
    end
  end
  
  def list_by_letter
    letter = params[:letter]
    if letter.blank?
      flash[:error] = "Buchstabe fehlt!"
      redirect_to :action => 'list'
      return
    end
    if letter == "*"
      sql = "select * from categories where category NOT REGEXP '[A-Z].*'"
    else
      sql = "select * from categories where category like ?"
    end
    sql += ' order by category'
    @categories = Category.paginate_by_sql [sql, "#{letter.first}%"], :page=>params[:page], :per_page=>10
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_category
      @category = Category.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def category_params
      # params.require(:category)
      # params.permit(:category, :description, :user_id)
      params.require(:category).permit(:category, :description, :public, :user_id)
    end
end
