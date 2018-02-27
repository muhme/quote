class QuotationsController < ApplicationController
  before_action :set_quotation, only: [:show, :edit, :update, :destroy]

  # GET /quotations
  # GET /quotations.json
  # get all public for not logged in users and
  # own entries for logged in users and all entries for admins
  def index
    sql_array = []
    search = ""
    search_and = ""
    pattern = params[:pattern]
    unless pattern.nil?
      search = " quotation like ? "
      search_and = " #{search} and "
    end
    
# TODO    
#    if not logged_in?
#      visibility = "public = 1"
#    elsif self.current_user.admin == true
#      visibility = ""
#    else
#      visibility = "( public = 1 or user_id = ? )"
#    end
#   
#    sql = 'select * from quotations'
#    sql += " where #{search_and} #{visibility}" if not logged_in? or self.current_user.admin != true;
#    sql += " where #{search}" if logged_in? and self.current_user.admin == true and ! pattern.nil?
#    sql << " order by id desc"
#    
#    sql_array << sql
#    sql_array << "%#{pattern}%" unless pattern.nil?
#    sql_array << self.current_user.id if logged_in? and self.current_user.admin != true
#    @quotations = Quotation.paginate_by_sql sql_array, :page=>params[:page], :per_page=>5
    @quotations = Quotation.paginate(page: params[:page], :per_page => 10)
        
    flash.now[:notice] = 'Die Zitate sind danach sortiert, wann sie eingestellt wurden. Die zuletzt eingestellten Zitate stehen oben.' unless ( params[:page] and params[:page].to_i > 1 )
  end

  # GET /quotations/1
  # GET /quotations/1.json
  def show
    @quotation = Quotation.find(params[:id])
    return unless access?(@quotation, :read)
  end

  # GET /quotations/new
  def new
    @quotation = Quotation.new
  end

  # GET /quotations/1/edit
  def edit
  end

  # POST /quotations
  # POST /quotations.json
  def create
    @quotation = Quotation.new(quotation_params)

    respond_to do |format|
      if @quotation.save
        format.html { redirect_to @quotation, notice: 'Quotation was successfully created.' }
        format.json { render :show, status: :created, location: @quotation }
      else
        format.html { render :new }
        format.json { render json: @quotation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /quotations/1
  # PATCH/PUT /quotations/1.json
  def update
    respond_to do |format|
      if @quotation.update(quotation_params)
        format.html { redirect_to @quotation, notice: 'Quotation was successfully updated.' }
        format.json { render :show, status: :ok, location: @quotation }
      else
        format.html { render :edit }
        format.json { render json: @quotation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /quotations/1
  # DELETE /quotations/1.json
  def destroy
    @quotation.destroy
    respond_to do |format|
      format.html { redirect_to quotations_url, notice: 'Quotation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  # list quotations created by a user
  def list_by_user
    user = params[:user]
    if user.blank?
      flash[:error] = "Kein Benutzer angegeben!"
      redirect_to :action => 'list'
      return false
    end
    
    sql = ["select distinct q.* from quotations q, users u where q.user_id = u.id and u.login = ? order by q.created_at desc", user]
    @quotations = Quotation.paginate_by_sql sql, :page=>params[:page], :per_page=>5
  end
  
  def list_by_category
    @category = Category.find params[:category]
    sql = 'select distinct q.* from quotations q, categories c, categories_quotations cq where category_id = ? and quotation_id = q.id'
# TODO
#    if not logged_in?
#      sql += " and q.public = 1"
#    elsif current_user.admin != true
#      sql += ' and ( q.public = 1 or q.user_id = ? )'
#    end
    
    sql_array = []
    sql_array << sql
    sql_array << params[:category]
# TODO
#    sql_array << self.current_user.id if logged_in? and self.current_user.admin != true;
    @quotations = Quotation.paginate_by_sql sql_array, :page=>params[:page], :per_page=>5
  end
  
  # select * from `quotations` where q.public = 1 and author_id = ?
  def list_by_author
    @author = Author.find params[:author]
    
    sql = 'select * from quotations where author_id = ?'
# TODO
#    if not logged_in?
#      sql += " and public = 1"
#    elsif self.current_user.admin != true
#     sql += ' and ( public = 1 or user_id = ? )'
#    end
    
    sql_array = [sql, params[:author]]
# TODO
#    sql_array << self.current_user.id if logged_in? and self.current_user.admin != true;
    @quotations = Quotation.paginate_by_sql sql_array, :page=>params[:page], :per_page=>5
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_quotation
      @quotation = Quotation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def quotation_params
      params.require(:quotation).permit(:quotation, :user_id, :author_id) # user_id + author_id TODO
    end
    
end