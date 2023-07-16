class AuthorsController < ApplicationController
  include ReusableMethods
  before_action :set_author, only: [:show, :edit, :update, :destroy]
  before_action :set_comments, only: [:show, :destroy]

  # GET /authors
  # get all public for not logged in users and
  # own entries for logged in users and all entries for admins
  def index
    sql = "select distinct * from authors a"
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
  end

  # POST /authors/search
  def search
    @authors = Author.filter_by_name(params[:author])
    logger.debug { "POST /authors/search found #{@authors.count} authors for \"#{params[:author]}\"" }
    render turbo_stream: turbo_stream.replace("search_author_results", partial: "quotations/search_author_results",
                                                                       locals: { authors: @authors })
  end

  # GET /authors/new
  def new
    return unless logged_in? t("authors.login_missing")

    @author = Author.new(user_id: current_user.id)
  end

  # GET /authors/1/edit only for admin or own user
  def edit
    return unless access?(:update, @author)
  end

  # POST /authors
  def create
    return unless logged_in? t("authors.login_missing")

    @author = Author.new(author_params)
    @author.user_id = current_user.id
    actual_locale = I18n.locale

    unless @author.valid?
      flash[:error] = e = @author.errors.any? ? @author.errors.first.full_message : "error"
      logger.error "create author not valid with #{e}"
      return render :new, status: :unprocessable_entity
    end

    begin
      # if we have wikipedia link, then find links in other locales and use author name from wikipedia
      ask_wikipedia(actual_locale)

      # translate description and name (if not already found on wikipedia)
      if !DeeplService.new.author_translate(actual_locale, @author)
        flash[:error] = t("g.machine_translation_failed", locale: actual_locale)
      end
    rescue Exception => exc
      # note problem with the translation and continue
      problem = "#{exc.class} #{exc.message}"
      logger.error "create author machine translation problem: #{problem}"
      flash[:error] = "#{t("g.machine_translation_failed")} #{problem}"
    end

    if @author.save
      return redirect_to author_path(@author, locale: I18n.locale),
                         notice: t(".created", author: @author.get_author_name_or_blank)
    else
      render :new, status: :unprocessable_entity
    end

  end

  # PATCH/PUT /authors/1
  def update
    return unless access?(:update, @author)

    author_params
    actual_locale = I18n.locale

    if params[:translate]
      @author.description = params[:author]["description_#{actual_locale}"] # TODO besser in author_params
      @author.firstname   = params[:author]["firstname_#{actual_locale}"]
      @author.name        = params[:author]["name_#{actual_locale}"]
      @author.link        = params[:author]["link_#{actual_locale}"]

      begin
        # if we have wikipedia link, then find links in other locales and use author name from wikipedia
        ask_wikipedia(actual_locale)

        # translate description and name (if not already found on wikipedia)
        if !DeeplService.new.author_translate(actual_locale, @author)
          flash[:error] = t("g.machine_translation_failed", locale: actual_locale)
        end
      rescue Exception => exc
        # note problem with the translation and continue
        problem = "#{exc.class} #{exc.message}"
        logger.error "update author machine translation problem: #{problem}"
        flash[:error] = "#{t("g.machine_translation_failed")} #{problem}"
      end
    else
      I18n.available_locales.each do |locale|
        @author.send("description_#{locale}=", params[:author]["description_#{locale}"])
        @author.send("firstname_#{locale}=", params[:author]["firstname_#{locale}"])
        @author.send("name_#{locale}=", params[:author]["name_#{locale}"])
        @author.send("link_#{locale}=", params[:author]["link_#{locale}"])
      end
    end

    @author.public = current_user.admin ? params[:author][:public] : false

    if @author.save
      return redirect_to author_path(@author, locale: I18n.locale),
                         notice: t(".updated", author: @author.get_author_name_or_blank)
    else
      flash[:error] = e = @author.errors.any? ? @author.errors.first.full_message : "error"
      logger.error "save author ID=#{@author&.id} – failed with #{e}"
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /authors/1
  def destroy
    return unless access?(:destroy, @author)

    if @author.destroy
      flash[:notice] = e = t(".deleted", author: @author.get_author_name_or_blank)
      logger.debug { "destroy author ID=#{@author.id} – #{e}" }
      redirect_to authors_url
    else
      flash[:error] = e = @author.errors.any? ? @author.errors.first.full_message : "error"
      logger.error "destroy author ID=#{@author&.id} – failed with #{e}"
      render :show, status: :unprocessable_entity
    end
  end

  # get authors list for a letter or all-no-letters
  # NICE only showing public or own entries to be extended like in index
  def list_by_letter
    letter = params[:letter].first.upcase
    sql = <<-SQL
    SELECT DISTINCT a.* FROM authors a
      INNER JOIN mobility_string_translations mst
        ON a.id = mst.translatable_id
        AND mst.translatable_type = 'Author'
        AND mst.locale = '#{I18n.locale.to_s}'
        AND mst.key = 'name'
      WHERE mst.value
    SQL
    if letter =~ /[#{ALL_LETTERS[I18n.locale].join}]/
      sql << " REGEXP '^[#{mapped_letters(letter)}]'"
    else
      # 1. needed to be handled here, as route restrictions constraints not trivial working with UTF8
      # 2. and we simple map all to "*" to ignore special cases like this letter is not part of actual locale letters
      params[:letter] = "*"
      sql << " NOT REGEXP '^[#{ALL_LETTERS[I18n.locale].join}]'"
    end
    sql << " ORDER BY mst.value"
    @authors = Author.paginate_by_sql sql, page: params[:page], per_page: PER_PAGE
    # check pagination second time with number of pages
    bad_pagination?(@authors.total_pages)
  end

  # for admins list all not public authors
  def list_no_public
    return unless access?(:admin, Author.new)

    @authors = Author.paginate_by_sql "select * from authors where public = 0", :page => params[:page], :per_page => 10
    # check pagination second time with number of pages
    bad_pagination?(@authors.total_pages)
  end

  private

  # if we have wikipedia link, then find links in other locales and use author name from wikipedia
  def ask_wikipedia(actual_locale)
    if @author.link =~ /http.*wikipedia.org\//
      # change http to https, delete mobile version, follow redirection
      @author.link = WikipediaService.new.clean_link(@author.link)
      result = WikipediaService.new.call(actual_locale, @author.link)
      links = result[:links]
      names = result[:names]
      I18n.available_locales.each do |locale|
        if locale != actual_locale
          @author.send("link_#{locale}=", links[locale.to_s])
          if names[locale.to_s].present?
            result = split_name(names[locale.to_s], locale)
            @author.send("firstname_#{locale}=", result[:firstname])
            @author.send("name_#{locale}=", result[:lastname])
          else
            @author.send("firstname_#{locale}=", nil)
            @author.send("name_#{locale}=", nil)
          end
        end
      end
    end
  end

  def set_author
    @author = Author.find(params[:id])
  rescue
    flash[:error] = t("authors.id_does_not_exist", id: params[:id])
    render "static_pages/not_found", status: :not_found
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def author_params
    permitted_params = []

    I18n.available_locales.each do |locale|
      permitted_params << "name_#{locale}".to_sym
      permitted_params << "firstname_#{locale}".to_sym
      permitted_params << "description_#{locale}".to_sym
      permitted_params << "link_#{locale}".to_sym
    end

    permitted_params << :public if current_user.admin?

    params.require(:author).permit(permitted_params).merge(user_id: current_user.id)
  end

  def set_comments
    @comments = Comment.where(commentable: @author)
    @commentable_type = "Author"
    @commentable_id = @author.id
  end

  def split_name(fullname, locale)
    delimiter = locale == :ja ? '・' : ' '
    parts = fullname.rpartition(delimiter)
    logger.debug("split_name #{parts.inspect}")
    { firstname: parts[0], lastname: parts[2] }
  end
end
