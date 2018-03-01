class AuthorsController < ApplicationController
  before_action :set_author, only: [:show, :edit, :update, :destroy]

  require 'will_paginate/array' # TODO to be removed?

  # GET /authors
  # GET /authors.json
  # get all public for not logged in users and
  # own entries for logged in users and all entries for admins
  def index
  
    sql = 'select * from authors a'
    sql += " where public = 1" if false # TODO not logged_in? or self.current_user.admin != true;
    sql += ' or user_id = ?' if false # logged_in? and self.current_user.admin != true;
    sql += params[:order] == 'authors' ?
      # by authors name and firstname alphabeticaly
      # using select with IF to sort the empty names authores at the end
      ' order by IF(a.name="","ZZZ",a.name), a.firstname' :
      # by the number of quotations that the authors have
      ' order by (select count(*) from quotations q where q.author_id = a.id) desc'
    
    @authors = Author.paginate_by_sql(sql, page: params[:page], :per_page => 10)
  end

  # GET /authors/1
  # GET /authors/1.json
  def show
    @author = Author.find(params[:id])
    return unless access?(@author, :read)
  end

  # GET /authors/new
  def new
    @author = Author.new
  end

  # GET /authors/1/edit
  def edit
  end

  # POST /authors
  # POST /authors.json
  def create
    @author = Author.new(author_params)
    @author.user_id = User.first.id # TODO hack, replace by actual user id

    respond_to do |format|
      if @author.save
        format.html { redirect_to @author, notice: "Der Author \"" + @author.get_author_name_or_blank + "\" wurde angelegt." }
        format.json { render :show, status: :created, location: @author }
      else
        format.html { render :new }
        format.json { render json: @author.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /authors/1
  # PATCH/PUT /authors/1.json
  def update
    respond_to do |format|
      if @author.update(author_params)
        format.html { redirect_to @author, notice: "Der Eintrag für den Author \"" + @author.get_author_name_or_blank + "\" wurde aktualisiert." }
        format.json { render :show, status: :ok, location: @author }
      else
        format.html { render :edit }
        format.json { render json: @author.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /authors/1
  # DELETE /authors/1.json
  def destroy
    @author.destroy
    respond_to do |format|
      format.html { redirect_to authors_url, notice: "Der Eintrag für den Author \"" + @author.get_author_name_or_blank + "\" wurde gelöscht." }
      format.json { head :no_content }
    end
  end
  
  def list_by_letter
    letter = params[:letter]
    if letter.blank?
      flush[:error] = "Buchstabe fehlt!"
      redirect_to :action => 'list'
      return
    end
    if letter == "*"
      sql = "select * from authors where name NOT REGEXP '[A-Z].*'"
    else
      sql = "select * from authors where name like ?"
    end
    sql += ' order by name, firstname'
    @authors = Author.paginate_by_sql [sql, "#{letter.first}%"], :page=>params[:page], :per_page=>10
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_author
      @author = Author.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def author_params
      params.require(:author).permit(:name, :firstname, :description, :link, :public, :user_id)  # user_id TODO
    end
end
