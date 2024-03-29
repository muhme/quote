class AuthorsController < ApplicationController
  include ReusableMethods
  before_action :set_author, only: [:show, :edit, :update, :destroy]
  before_action :set_comments, only: [:show, :destroy]

  # GET /authors
  def index
    if params[:order] == "authors"
      # order by authors (last) name, and order authors w/o (last) name at the end
      authors_with_name = Author.i18n.where.not(name: [nil, ""]).order(name: :asc, firstname: :asc)
      authors_without_name = Author.i18n.where(name: [nil, ""]).order(firstname: :asc)
      @authors = authors_with_name + authors_without_name # this creates an array, we loose the ActiveRecord relation
      # Convert the authors array back to an ActiveRecord relation
      author_ids = @authors.map(&:id)
      @authors = Author.in_order_of(:id, author_ids)
      # TODO: this is not perfect working in :ja and :uk as there are also *-characters in the beginning of the list
    else
      # 'simple' order by the number of quotations
      @authors = Author.left_joins(:quotations).group(:id).order('COUNT(quotations.id) DESC')
    end

    # Pagination with will_paginate
    @authors = @authors.paginate(page: params[:page], per_page: 10)

    # Check pagination second time with number of pages
    bad_pagination?(@authors.total_pages)
  end

  # GET /authors/1
  def show
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

    # set https if needed and possible and follow redirects, if not reachable set flash[:warning]
    verify_and_improve_link(:new)

    begin
      # if we have wikipedia link, then find links in other locales and use author name from wikipedia
      WikipediaService.new.ask_wikipedia(actual_locale, @author)

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
        # first clean name and firstname to distingues it is already set by wikipedia or not
        (I18n.available_locales - [actual_locale]).each do |locale|
          @author.send("description_#{locale}=", nil)
          @author.send("firstname_#{locale}=", nil)
          @author.send("name_#{locale}=", nil)
          @author.send("link_#{locale}=", nil)
        end

        # set https if needed and possible and follow redirects, if not reachable set flash[:warning]
        verify_and_improve_link(:edit)

        # if we have wikipedia link, then find links in other locales and use author name from wikipedia
        WikipediaService.new.ask_wikipedia(actual_locale, @author)

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
        # set https if needed and possible and follow redirects, if not reachable set flash[:warning]
        verify_and_improve_link(:edit, locale)
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

    author_name = @author.get_author_name_or_blank
    if @author.destroy
      flash[:notice] = e = t(".deleted", author: author_name)
      logger.debug { "destroy author ID=#{@author.id} – #{e}" }
      redirect_to authors_url
    else
      flash[:error] = e = @author.errors.any? ? @author.errors.first.full_message : "error"
      logger.error "destroy author ID=#{@author&.id} – failed with #{e}"
      render :show, status: :unprocessable_entity
    end
  end

  # get authors list for first name letter or all-no-letters and no-name
  # NICE only showing public or own entries to be extended like in index
  def list_by_letter
    letter = params[:letter].first.upcase
    sql = <<-SQL
    SELECT DISTINCT a.* FROM authors a
      LEFT JOIN mobility_string_translations mst
        ON a.id = mst.translatable_id
        AND mst.translatable_type = 'Author'
        AND mst.key = 'name'
        AND mst.locale = '#{I18n.locale.to_s}'
      WHERE
    SQL
    if letter =~ /[#{ALL_LETTERS[I18n.locale].join}]/
      sql << "mst.value REGEXP '^[#{mapped_letters(letter)}]'"
    else
      # 1. needed to be handled here, as route restrictions constraints not trivial working with UTF8
      # 2. and we simple map all to "*" to ignore special cases like this letter is not part of actual locale letters
      params[:letter] = "*"
      sql << "(mst.value NOT REGEXP '^[#{ALL_LETTERS[I18n.locale].join}]' OR mst.value IS NULL OR mst.value = '')"
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

  # reading from and writing on @author.link with locale
  # change http to https, URL unencode and verify URL is reachable
  # doing it by default for the actual locale (from create or translate) or
  # for given locale in case of save, where the method has to be called for all locales
  # if link is not reachable writes into flash[:warning]
  def verify_and_improve_link(to_render, locale = I18n.locale)
    new_link = UrlCheckerService.check(@author.link(locale: locale))
    if @author.link(locale: locale).present? and new_link.nil?
      # add warning as we can have it multiple times with the locales
      flash[:warning] = (flash[:warning].present? ? flash[:warning] + " " : "") +
                        t("g.link_invalid", link: @author.link(locale: locale))
      logger.info { "invalid link #{@author.link(locale: locale)}" }
    elsif new_link != @author.link(locale: locale)
      # add error as we can have it multiple times with the locales
      flash[:warning] = (flash[:warning].present? ? flash[:warning] + " " : "") +
                        t("g.link_changed", link: @author.link(locale: locale), new: new_link)
      logger.info "link in locale #{locale} changed from #{@author.link(locale: locale)} to #{new_link}"
      @author.send("link_#{locale}=", new_link)
    end
  end
end
