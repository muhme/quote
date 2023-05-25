class AuthorsController < ApplicationController
  before_action :set_author, only: [:show, :edit, :update, :destroy]
  before_action :set_comments, only: [:show, :destroy]

  # GET /authors
  # get all public for not logged in users and
  # own entries for logged in users and all entries for admins
  def index
    sql = "select distinct * from authors a"
    sql += " where public = 1" if not current_user or current_user.admin != true
    sql += " or user_id = #{current_user.id}" if current_user and current_user.admin != true
    sql += params[:order] == "authors" ?
    # by authors name and firstname alphabeticaly
    # using select with IF to sort the empty names authores at the end
      ' order by IF(a.name="","ZZZ",a.name), a.firstname' :
    # by the number of quotations that the authors have
      " order by (select count(*) from quotations q where q.author_id = a.id) desc"

    @authors = Author.paginate_by_sql(sql, page: params[:page], :per_page => 10)
    # check pagination second time with number of pages
    bad_pagination?(@authors.total_pages)
  end

  # GET /authors/1
  def show
    return unless access?(@author, :read)
  end

  # POST /authors/search
  def search
    @authors = Author.filter_by_name(params[:author])
    logger.debug { "POST /authors/search found #{@authors.count} authors for \"#{params[:author]}\"" }
    render turbo_stream: turbo_stream.replace("search_author_results", partial: "quotations/search_author_results", locals: { authors: @authors })
  end

  # GET /authors/new
  def new
    return unless logged_in? t("authors.login_missing")
    @author = Author.new(user_id: current_user.id)
  end

  # GET /authors/1/edit only for admin or own user
  def edit
    return unless access?(@author, :update)
  end

  # POST /authors
  def create
    return unless logged_in? t("authors.login_missing")
    @author = Author.new(author_params)
    @author.user_id = current_user.id

    if @author.save
      return redirect_to author_path(@author, locale: I18n.locale), notice: t(".created", author: @author.get_author_name_or_blank)
    else
      render :new, status: :unprocessable_entity
    end

    # NICE give warning if the same autor already exists

  rescue Exception => exc
    logger.error "create author failed: #{exc.message}"
    flash[:error] = t(".failed", author: @author.get_author_name_or_blank, exception: exc.message)
  end

  # PATCH/PUT /authors/1
  def update
    return unless access?(@author, :update)

    if @author.update author_params
      return redirect_to author_path(@author, locale: I18n.locale), notice: t(".updated", author: @author.get_author_name_or_blank)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /authors/1
  def destroy
    return unless access?(@author, :destroy)
    if @author.destroy
      flash[:notice] = e = t(".deleted", author: @author.get_author_name_or_blank)
      logger.debug { "destroy author ID=#{@author.id} – #{e}" }
      redirect_to authors_url
    else
      flash[:error] = e = @author.errors.any? ? @author.errors.first.full_message : "error"
      logger.error "destroy author ID=#{@author.id} – failed with #{e}"
      render :show, status: :unprocessable_entity
    end
  end

  # get authors list for a letter or all-no-letters
  # NICE only showing public or own entries to be extended like in index
  def list_by_letter
    letter = params[:letter]
    if letter == "*"
      sql = "select * from authors where name NOT REGEXP '^[A-Z].*'"
    elsif letter =~ /[A-Za-z]/
      sql = "select * from authors where name like ?"
    else # not reachable, because route restrictions already forbid it - but, just in case
      flash[:error] = t(".letter_missing")
      redirect_to :action => "list"
      return
    end
    sql += " order by name, firstname"
    @authors = Author.paginate_by_sql [sql, "#{letter.first}%"], :page => params[:page], :per_page => 10
    # check pagination second time with number of pages
    bad_pagination?(@authors.total_pages)
  end

  # for admins list all not public authors
  def list_no_public
    if !current_user or current_user.admin == false
      flash[:error] = t("g.no_admin")
      redirect_to authors_url
      return false
    end
    @authors = Author.paginate_by_sql "select * from authors where public = 0", :page => params[:page], :per_page => 10
    # check pagination second time with number of pages
    bad_pagination?(@authors.total_pages)
  end

  private

  def set_author
    @author = Author.find(params[:id])
  rescue
    flash[:error] = t("authors.id_does_not_exist", id: params[:id])
    render "static_pages/not_found", status: :not_found
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def author_params
    params.require(:author).permit(:name, :firstname, :description, :link, :public)
  end

  def set_comments
    @comments = Comment.where(commentable: @author)
    @commentable_type = "Author"
    @commentable_id = @author.id
  end
end
