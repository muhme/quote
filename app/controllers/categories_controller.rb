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
    
    # TODO @categories = Category.paginate_by_sql [sql, self.current_user.id], :page=>params[:page], :per_page=>10
    @categories = Category.paginate(page: params[:page], :per_page => 10)
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
  end

  # GET /categories/1/edit
  def edit
  end

  # POST /categories
  # POST /categories.json
  def create
    @category = Category.new(category_params)

    respond_to do |format|
      if @category.save
        format.html { redirect_to @category, notice: 'Category was successfully created.' }
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
    @category.destroy
    respond_to do |format|
      format.html { redirect_to categories_url, notice: 'Category was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_category
      @category = Category.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def category_params
      params.require(:category).permit(:category, :description, :user_id)  # user_id TODO
    end
end
