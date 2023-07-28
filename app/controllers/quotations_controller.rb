class QuotationsController < ApplicationController
  include ActionView::Helpers::TextHelper # for truncate()
  before_action :set_quotation, only: [:show, :edit, :update, :destroy]
  before_action :category_ids_param_to_array
  before_action :set_comments, only: [:show, :destroy]

  # GET /quotations
  # GET /quotations?pattern=berlin
  # GET /quotations?page=42
  # get all public for not logged in users and own entries for logged in users and all entries for admins
  def index
    pattern = params[:pattern].blank? ? "%" : my_sql_sanitize(params[:pattern])
    sql = "select distinct * from quotations where quotation like '%" + pattern + "%' "
    sql += " order by id desc"

    @quotations = Quotation.paginate_by_sql(sql, page: params[:page], :per_page => 5)
    # check pagination second time with number of pages
    bad_pagination?(@quotations.total_pages)

    # give hint on first page if no other notice exist
    if !flash[:notice] and (!params[:page] or params[:page].to_i == 1)
      flash.now[:notice] = t(".order")
    end
  end

  # GET /quotations/1
  def show
  end

  # GET /quotations/new
  def new
    return unless logged_in? t("quotations.login_missing")

    @quotation = Quotation.new(user_id: current_user.id)
  end

  # GET /quotations/1/edit
  def edit
    return unless access?(:update, @quotation)
  end

  # GET quotations/author_selected/author_id
  # called from search author result list as a click on a link
  def author_selected
    return unless logged_in? t("quotations.login_missing")

    turbo_author(nil, params[:author_id])
    render turbo_stream: turbo_stream_do_actions
  end

  # GET quotations/category_selected/327,139,42-44,45
  # called from search category result list as a click on a link
  # with all choosen categories left and all recommended categories right from minus separator
  # first entry in the choosen categories list is the new selected category
  def category_selected
    return unless logged_in? t("quotations.login_missing")

    category_ids = split_two_id_arrays(params[:ids], 0)
    category_id = category_ids[0]
    rec_ids = split_two_id_arrays(params[:ids], 1)
    logger.debug {
      "category_selected() category_id=#{nol(category_id)} " +
        "category_ids=#{nol(category_ids, true)} rec_ids=#{nol(rec_ids, true)}"
    }
    turbo_category(category_id, category_ids, rec_ids)
    render turbo_stream: turbo_stream_do_actions
  end

  # GET quotations/delete_category/305,487-44,45
  # called from each collected category to delete
  # only remaining categories are given in the list, left from minus separator
  # list of remaining categories is empty in case the last category is to delete
  # right from minus separator is the list of recommended categories
  def delete_category
    return unless logged_in? t("quotations.login_missing")

    category_ids = split_two_id_arrays(params[:ids], 0)
    rec_ids = split_two_id_arrays(params[:ids], 1)
    logger.debug { "delete_category() category_ids=#{nol(category_ids, true)} rec_ids=#{nol(rec_ids, true)}" }
    turbo_category(nil, category_ids, rec_ids)
    render turbo_stream: turbo_stream_do_actions
  end

  # POST /quotations
  def create
    return unless logged_in? t("quotations.login_missing")

    # set @authors and @categories from autocompletion fields and return hidden fields authors ID and category IDs
    author_id, category_ids = scan_params_for_create_or_update

    if params[:commit]
      @quotation = Quotation.new(quotation_params)
      return unless verify_and_improve_link(:new)

      @quotation.user_id = current_user.id
      @quotation.author_id = 0 unless @quotation.author_id # empty author field is an unknown author, which has id 0
      logger.debug { "saving #{@quotation.inspect}" }
      if @quotation.save
        hint = t(".created", id: @quotation.id)
        # give hint, e.g. if author autocomplete field is empty and unknown author is used
        hint << " #{t(".author_used", author: Author.find(@quotation.author_id).name)}" if @authors.count != 1
        return redirect_to quotation_path(@quotation, locale: I18n.locale), notice: hint
      else
        render :new, status: :unprocessable_entity
      end
    else
      turbo_author(author_id)
      turbo_category(nil, category_ids, Category.check(params[:quotation][:quotation]))
      render turbo_stream: turbo_stream_do_actions
    end
  rescue Exception => exc
    problem = "#{exc.class} #{exc.message}"
    logger.error "create quotation failed: #{problem}"
    flash[:error] = t(".failed", exception: problem)
    render :new, status: :unprocessable_entity
  end

  # PATCH/PUT /quotations/1
  def update
    return unless access?(:update, @quotation)

    # set @authors and @categories from autocompletion fields and return hidden fields authors ID and category IDs
    author_id, category_ids = scan_params_for_create_or_update

    if params[:commit]
      # Are associated categories changed? Compare from params with existing list by hand as changed? does not exist for has_and_belongs_to_many.
      categories_changed = category_ids.sort != @quotation.category_ids.sort
      @quotation.assign_attributes(quotation_params)
      return unless verify_and_improve_link(:edit)

      logger.debug { "update() categories_changed=#{categories_changed}, quotation.changed #{@quotation.changes}" }
      if @quotation.changed? or categories_changed
        if @quotation.save
          # set Quotation.updated_at even if there are changes in associated categories
          @quotation.touch if categories_changed
          hint = t(".updated")
          # give hint, e.g. if author autocomplete field is not completed
          hint << " #{t(".author_unchanged", author: Author.find(@quotation.author_id).name)}" if @authors.count != 1
          return redirect_to quotation_path(@quotation, locale: I18n.locale), notice: hint
        else
          render :edit, status: :unprocessable_entity
        end
      else # quotation and associated categories are unchanged
        hint = t(".unchanged")
        # give hint, e.g. if author autocomplete field is not completed
        hint << " #{t(".author_unchanged", author: Author.find(@quotation.author_id).name)}" if @authors.count != 1
        return redirect_to @quotation, notice: hint
      end
    else
      turbo_author(author_id)
      turbo_category(nil, category_ids, Category.check(@quotation))
      render turbo_stream: turbo_stream_do_actions
    end
  end

  # DELETE /quotations/1
  def destroy
    return unless access?(:destroy, @quotation)

    if @quotation.destroy
      flash[:notice] = e = t(".deleted", quote: truncate(@quotation.quotation, length: 20))
      logger.debug { "destroyed quotation ID=#{@quotation.id} – #{e}" }
      redirect_to quotations_url
    else
      flash[:error] = e = @quotation.errors.any? ? @quotation.errors.first.full_message : "error"
      logger.error "destroy quotation ID=#{@quotation.id} – failed with #{e}"
      render :show, status: :unprocessable_entity
    end
  end

  # list quotations created by a user
  def list_by_user
    unless User.exists?(:id => params[:user])
      flash[:error] = t(".no_user", user: params[:user])
      return redirect_to root_url
    end

    sql = ["select distinct * from quotations where user_id = ? order by created_at desc",
           my_sql_sanitize(params[:user])]
    @quotations = Quotation.paginate_by_sql sql, :page => params[:page], :per_page => 5
    # check pagination second time with number of pages
    bad_pagination?(@quotations.total_pages)
  end

  def list_by_category
    unless Category.exists? params[:category]
      flash[:error] = t(".no_category", id: params[:category])
      return redirect_to root_url
    end
    @category = Category.find params[:category]
    @quotations = Quotation.paginate_by_sql sql_quotations_for_category(@category.id), :page => params[:page],
                                                                                       :per_page => 5
    # check pagination second time with number of pages
    bad_pagination?(@quotations.total_pages)
  end

  # select * from `quotations` where q.public = 1 and author_id = ?
  def list_by_author
    unless Author.exists? params[:author]
      flash[:error] = t(".no_author", id: params[:author])
      return redirect_to root_url
    end
    @author = Author.find params[:author]
    @quotations = Quotation.paginate_by_sql sql_quotations_for_author(@author.id), :page => params[:page],
                                                                                   :per_page => 5
    # check pagination second time with number of pages
    bad_pagination?(@quotations.total_pages)
  end

  # for admins list all not public categories
  def list_no_public
    return unless access?(:admin, Quotation.new)

    @quotations = Quotation.paginate_by_sql "select * from quotations where public = 0", :page => params[:page],
                                                                                         :per_page => 5
    # check pagination second time with number of pages
    bad_pagination?(@quotations.total_pages)
  end

  private

  def set_quotation
    @quotation = Quotation.find(params[:id])
  rescue
    flash[:error] = t("quotations.id_does_not_exist", id: params[:id])
    render "static_pages/not_found", status: :not_found
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def quotation_params
    # source and source_link are optional and saved as NULL in database if blank
    params[:quotation][:source]      = nil if params[:quotation][:source].blank?
    params[:quotation][:source_link] = nil if params[:quotation][:source_link].blank?
    params.require(:quotation).permit(:author_id, :quotation, :source, :source_link, :public, :pattern,
                                      :category_ids => [])
  end

  # categories are collected as one string in hidden field, transform in place to an array
  # e.g. "category_ids"=>["305,272"] into "category_ids"=>["305", "272"]
  # is used as before_action on every request, if the parameter is not present, there is simply nothing to do
  def category_ids_param_to_array
    if params and params[:quotation] and
       params[:quotation][:category_ids] and
       params[:quotation][:category_ids].kind_of?(Array) and
       params[:quotation][:category_ids][0].present? and
       params[:quotation][:category_ids][0].is_a?(String)
      params[:quotation][:category_ids] = params[:quotation][:category_ids][0].split(",")
    end
  end

  # One or two Turbo Stream updates for author autocompletion.
  # One Turbo Stream update for partial search author result list and
  # if we have exactly one author entry:
  #   - do one more Turbo Stream update to fill partial search author field with "name, firstname, comment" and
  #   - use an empty array to make the partial search author result list disappear
  # author_id     - to fill author field with name, firstname and comment
  # old_author_id - to decide to animate
  # @authors      - up to 10 entries (Array Author[], nil)
  def turbo_author(old_author_id, author_id = nil)
    if @authors and @authors.count == 1
      author_id = @authors.first.id
      authors = [] # empty list let the selection list disappear
    else
      authors = @authors
    end

    logger.debug {
      "turbo_author() old_author_id=#{nol(old_author_id)}, author_id=#{nol(author_id)}, authors=#{nol(authors)}"
    }

    # author selection list for the letters submitted so far
    turbo_stream_add_update("search_author_results", partial: "quotations/search_author_results",
                                                     locals: { authors: authors })
    # fill author field if there is exactly one entry and animate it if there is a change
    author_id && turbo_stream_add_update("search_author", partial: "quotations/search_author",
                                                          locals: { author_id: author_id, animation: old_author_id.to_i != author_id.to_i ? :animated : :none })
  end

  # Two Turbo Stream Updates for category autocompletion. Add a new category:
  #   #1 category_id is set from category_selected() as click on a link from authors list or recommendation list
  #   #2 given letters match exactly one entry in @categories
  # One Turbo update for partial search_category_result list with up to 10 categories. If the @categories list is empty it disappers.
  # Second Turbo update for partial search_category_collected with:
  #   - update hidden field quotation[category_ids] and
  #   - show list of so far collected categories, linked with delete category action
  #   - show list of recommended categories, linked with category_selected action
  #   - set CSS class="animated" for new added category
  #
  # category_id  - new added category (Integer, nil)
  # category_ids - all category IDs collected so far (String/Array)
  # rec_ids      - recommended category IDs (Array)
  # @categories  - up to 10 entries (Array Category[], nil)
  def turbo_category(category_id, category_ids, rec_ids)
    logger.debug {
      "turbo_category() category_id=#{nol(category_id)}, " +
        "@categories=#{nol(@categories)}, category_ids=#{nol(category_ids, true)} " +
        "rec_ids=#{nol(rec_ids, true)}"
    }

    # ensure category_ids existing as array
    category_ids = ids_to_array(category_ids)
    # 1st case - clicked on autocomplete link
    if category_id.present?
      category_ids = [category_id] | category_ids
      categories = []
      # 2nd case - only one entry in autocomplete list left
    elsif @categories and @categories.count == 1
      category_id = @categories.first.id
      category_ids = [category_id] | category_ids
      categories = []
    else # 3rd case - updating the autocomplete list
      categories = @categories
    end

    logger.debug {
      "turbo_category() category_id=#{nol(category_id)}, " +
        "categories=#{nol(categories)}, category_ids=#{nol(category_ids, true)}, " +
        "rec_ids=#{nol(rec_ids, true)}"
    }

    # update the automplete search list or let the list disappear with categories []
    turbo_stream_add_update("search_category_results", partial: "quotations/search_category_results",
                                                       locals: { categories: categories, category_ids: category_ids, rec_ids: rec_ids })

    # update hidden field quotation[category_ids] and show list of collected and recommended categories
    turbo_stream_add_update("search_category_collected", partial: "quotations/search_category_collected",
                                                         locals: { categories: categories, category_id: category_id, category_ids: category_ids, rec_ids: rec_ids })
  end

  # return [] for "" or "[]" or [""]
  # return [42,4711] for "42,4711" or "[42,4711]" or [42,4711]
  # returns [305, 464] for ["305", "464"]
  def ids_to_array(ids)
    if ids.blank? or ids == "[]" or (ids.is_a?(Array) and ids.count == 1 and ids[0].blank?)
      ids = []
    elsif ids.is_a?(String)
      ids = ids.tr("[]", "").split(",").map(&:to_i)
    end
    return ids.map(&:to_i)
  end

  # set @authors and @categories from autocompletion fields and return hidden fields authors ID and category IDs
  # scan params for create or update
  # - hidden field [:quotation][:author_id] returns old author ID
  # - hidden field [:quotation][:category_ids] returns list of old category IDs
  # - autocomplete field [:author] with first letters from "name, firstname, comment"
  #    -> this fills @authors
  # - autocomplete field [:category] with first letters
  #    -> this fills @categories
  # returns author ID and category IDs from hidden fields
  def scan_params_for_create_or_update
    author_id = params[:quotation][:author_id]
    category_ids = ids_to_array(params[:quotation][:category_ids])
    @authors = Author.filter_by_name_firstname_description(my_sql_sanitize(params[:author]))
    logger.debug { "#{@authors.count} authors found for #{nol(params[:author])}" }
    @categories = Category.filter_by_category(my_sql_sanitize(params[:category]), category_ids)
    logger.debug {
      "#{@categories.count} categories found for #{nol(params[:category])} and without #{nol(category_ids, true)}}"
    }
    return [author_id, category_ids]
  end

  # split two ID list, separated by minus
  # "327,139,42-44,45"
  # pos is 0 or 1
  def split_two_id_arrays(param, pos)
    splitted = param.split("-") if param
    return param && splitted[pos] ? splitted[pos].split(",").map(&:to_i) : []
  end

  def set_comments
    @comments = Comment.where(commentable: @quotation)
    @commentable_type = "Quotation"
    @commentable_id = @quotation.id
  end

  def verify_and_improve_link(to_render)
    new_link = UrlCheckerService.check(@quotation.source_link)
    if @quotation.source_link.present? and new_link.nil?
      flash[:error] = t("g.link_invalid", link: @quotation.source_link)
      logger.info { "invalid link #{@quotation.source_link}" }
      render to_render, status: :unprocessable_entity
      return false
    end
    if new_link != @quotation.source_link
      flash[:error] = t("g.link_changed", link: @quotation.source_link, new: new_link) # TODO change to :warn
      logger.info "link changed from #{@quotation.source_link} to #{new_link}"
      @quotation.source_link = new_link
    end
    return true
  end
end
