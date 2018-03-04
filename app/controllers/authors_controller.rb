class AuthorsController < ApplicationController
  before_action :set_author, only: [:show, :edit, :update, :destroy]

  # GET /authors
  # get all public for not logged in users and
  # own entries for logged in users and all entries for admins
  def index
  
    sql =  "select * from authors a"
    sql += " where public = 1" if not current_user or current_user.admin != true
    sql += " or user_id = #{current_user.id}" if current_user and current_user.admin != true
    sql += params[:order] == 'authors' ?
      # by authors name and firstname alphabeticaly
      # using select with IF to sort the empty names authores at the end
      ' order by IF(a.name="","ZZZ",a.name), a.firstname' :
      # by the number of quotations that the authors have
      ' order by (select count(*) from quotations q where q.author_id = a.id) desc'
  
    @authors = Author.paginate_by_sql(sql, page: params[:page], :per_page => 10)
  end

  # GET /authors/1
  def show
    return unless access?(@author, :read)
  end

  # GET /authors/new
  def new
    @author = Author.new
    if current_user
      @author.user_id = current_user.id
    else
      flash[:error] = "Anmeldung fehlt, um einen neuen Autor-Eintrag anzulegen!"
      redirect_to forbidden_url 
    end
  end

  # GET /authors/1/edit only for admin or own user
  def edit
    return unless access?(@author, :update)
  end

  # POST /authors
  def create
    @author = Author.new(author_params)
    if current_user
      @author.user_id = current_user.id
    else
      flash[:error] = "Anmeldung fehlt, um einen neuen Autor-Eintrag anzulegen!"
      redirect_to forbidden_url 
    end

    if @author.save
      redirect_to @author, notice: "Der Author \"" + @author.get_author_name_or_blank + "\" wurde angelegt."
    else
      render :new
    end
    
    # NICE give warning if the same autor already exists
    
    rescue Exception => exc
      logger.error "create author  failed: #{exc.message}"
      flash[:error] = "Das Anlegen des Autors \"" + @author.get_author_name_or_blank + "\" ist gescheitert! (#{exc.message})"
  end

  # PATCH/PUT /authors/1
  def update
    return unless access?(@author, :update)
    if @author.update author_params
      redirect_to @author, notice: "Der Eintrag für den Author \"" + @author.get_author_name_or_blank + "\" wurde aktualisiert."
    else
      render :edit
    end
  end

  # DELETE /authors/1
  def destroy
    return unless access?(@author, :destroy)
    n = @author.quotations.size
    if n > 0
      flash[:error] = "Der Author \"" + @author.get_author_name_or_blank + "\" hat #{n} Zitate und kann nicht gelöscht werden."
      redirect_to :action => 'show', :id => @author.id
    else
      if @author.destroy
        flash[:notice] = "Der Eintrag für den Author \"" + @author.get_author_name_or_blank + "\" wurde gelöscht."
      end
      redirect_to authors_url
    end
  end

  # get authors list for a letter or all-no-letters
  # NICE only showing public or own entries to be extended like in index
  def list_by_letter
    letter = params[:letter]
    if letter.blank?
      flash[:error] = "Buchstabe fehlt!"
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
  
  # for admins list all not public authors
  def list_no_public
    if !current_user or current_user.admin == false
      flash[:error] = "Kein Administrator!"
      redirect_to :action => 'list'
      return false
    end
    @authors = Author.paginate_by_sql 'select * from authors where public = 0', :page=>params[:page], :per_page=>10
  end

  private

    def set_author
      @author = Author.find(params[:id])
      rescue
        flash[:error] = "Es gibt keinen Autor mit der ID \"#{params[:id]}\"."
        redirect_to not_found_url
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def author_params
      params.require(:author).permit(:name, :firstname, :description, :link, :public)
    end
end
