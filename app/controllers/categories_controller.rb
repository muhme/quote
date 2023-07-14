class CategoriesController < ApplicationController
  include ReusableMethods
  before_action :set_category, only: [:show, :edit, :update, :translate, :destroy]
  before_action :set_comments, only: [:show, :destroy]

  # GET /categories
  def index
    sql = <<-SQL
      SELECT DISTINCT c.*, COALESCE(mst.value, mst_en.value) AS value FROM categories c
        LEFT JOIN mobility_string_translations mst
          ON c.id = mst.translatable_id
          AND mst.translatable_type = 'Category'
          AND mst.locale = '#{I18n.locale}'
          AND mst.key = 'category'
        LEFT JOIN mobility_string_translations mst_en
          ON c.id = mst_en.translatable_id
          AND mst_en.translatable_type = 'Category'
          AND mst_en.locale = 'en'
          AND mst_en.key = 'category'
    SQL

    sql += params[:order] == "categories" ?
        # by category name alphabetically
        " ORDER BY COALESCE(mst.value, mst_en.value)" :
        # by the number of quotations that the categories have
        " ORDER BY (SELECT COUNT(*) FROM categories_quotations cq, quotations q WHERE cq.quotation_id = q.id AND cq.category_id = c.id) DESC"

    @categories = Category.paginate_by_sql(sql, page: params[:page], :per_page => PER_PAGE)
    # check pagination second time with number of pages
    bad_pagination?(@categories.total_pages)
  end

  # GET /categories/1
  def show
    sql = <<-SQL
      SELECT DISTINCT t1.locale, t2.translatable_id AS t2
        FROM mobility_string_translations t1
        JOIN mobility_string_translations t2
          ON t1.value = t2.value
          AND t1.locale = t2.locale
          AND t1.locale IN ('en', 'de', 'es', 'ja', 'uk')
          AND t1.translatable_id <> t2.translatable_id
          AND t1.translatable_type = 'Category'
          AND t2.translatable_type = 'Category'
          AND t1.key = 'category'
          AND t2.key = 'category'
        WHERE t1.translatable_id = #{@category.id};
    SQL
    result = ActiveRecord::Base.connection.execute(sql)
    @duplicate = {}
    result.each do |row|
      locale = row[0]
      id = row[1]
      @duplicate[locale] = id
    end

    logger.debug { "found #{@duplicate.to_s}" }
  end

  # GET /categories/new
  def new
    return unless logged_in? t("categories.login_missing")

    @category = Category.new(user_id: current_user.id)
  end

  # GET /categories/1/edit only for admin or own user
  def edit
    return unless access?(:update, @category)
  end

  # POST /categories
  def create
    return unless logged_in? t("categories.login_missing")

    @category = Category.new(category_params)

    unless @category.valid?
      flash[:error] = e = @category.errors.any? ? @category.errors.first.full_message : "error"
      logger.error "create category not valid with #{e}"
      return render :new, status: :unprocessable_entity
    end

    actual_locale = I18n.locale
    error_logged = false
    I18n.available_locales.each do |locale|
      if locale != actual_locale
        translated = deepl_translate_words(@category.category(locale: actual_locale), actual_locale, locale)
        if translated.present?
          @category.send("category_#{locale}=", translated)
        elsif !error_logged
          flash[:error] = t("g.machine_translation_failed")
          error_logged = true
        end
      end
    end
    @category.public = current_user.admin ? params[:category][:public] : false

    if @category.save
      return redirect_to category_path(@category, locale: I18n.locale),
                         notice: t(".created", category: @category.category)
    else
      flash[:error] = e = @category.errors.any? ? @category.errors.first.full_message : "error"
      logger.error "create failed with #{e}"
      render :new, status: :unprocessable_entity
    end
  rescue Exception => exc
    problem = "#{exc.class} #{exc.message}"
    logger.error "create category failed: #{problem}"
    flash[:error] = t(".failed", category: @category.category, exception: problem)
    render :new, status: :unprocessable_entity
  end

  # PATCH/PUT /categories/1
  def update
    return unless access?(:update, @category)

    category_params
    actual_locale = I18n.locale
    error_logged = false
    I18n.available_locales.each do |locale|
      if params[:translate]
        if locale == actual_locale
          @category.category = params[:category]["category_#{locale}"]
        else
          translated = deepl_translate_words(params[:category]["category_#{actual_locale}"], actual_locale, locale)
          if translated.present?
            @category.send("category_#{locale}=", translated)
          elsif !error_logged
            flash[:error] = t("g.machine_translation_failed", locale: actual_locale)
            error_logged = true
          end
        end
      else
        @category.send("category_#{locale}=", params[:category]["category_#{locale}"])
      end
    end
    @category.public = current_user.admin ? params[:category][:public] : false

    if @category.save
      return redirect_to category_path(@category, locale: I18n.locale),
                         notice: t(".updated", category: @category.category)
    else
      flash[:error] = e = @category.errors.any? ? @category.errors.first.full_message : "error"
      logger.error "save category ID=#{@category.id} – failed with #{e}"
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /categories/1
  def destroy
    return unless access?(:destroy, @category)

    category = @category.category
    if @category.destroy
      flash[:notice] = e = t(".deleted", category: category)
      logger.debug { "destroy category ID=#{@category.id} – #{e}" }
      redirect_to categories_url
    else
      flash[:error] = e = @category.errors.any? ? @category.errors.first.full_message : "error"
      logger.error "destroy category ID=#{@category.id} – failed with #{e}"
      render :show, status: :unprocessable_entity
    end
  end

  # get category list for a letter or all-no-letters
  def list_by_letter
    letter = params[:letter].first.upcase
    # first LEFT JOIN attempts to get the translation in the current locale, and the second one gets the English translation as default
    # The COALESCE function returns the first non-null argument, so it will use the current locale's translation if available, otherwise,
    # it falls back to English.
    sql = <<-SQL
      SELECT DISTINCT c.*, COALESCE(mst.value, mst_en.value) AS value
      FROM categories c
      LEFT JOIN mobility_string_translations mst
          ON c.id = mst.translatable_id
          AND mst.translatable_type = 'Category'
          AND mst.key = 'category'
          AND mst.locale = '#{I18n.locale.to_s}'
      LEFT JOIN mobility_string_translations mst_en
          ON c.id = mst_en.translatable_id
          AND mst_en.translatable_type = 'Category'
          AND mst_en.key = 'category'
          AND mst_en.locale = 'en'
      WHERE (SELECT COALESCE(mst.value, mst_en.value))
    SQL
    if letter =~ /[#{ALL_LETTERS[I18n.locale].join}]/
      sql << " REGEXP '^[#{mapped_letters(letter)}]'"
    else
      # 1. needed to be handled here, as route restrictions constraints not trivial working with UTF8
      # 2. and we simple map all to "*" to ignore special cases like this letter is not part of actual locale letters
      params[:letter] = '*'
      sql << " NOT REGEXP '^[#{ALL_LETTERS[I18n.locale].join}]'"
    end
    sql << " ORDER BY COALESCE(mst.value, mst_en.value)"
    @categories = Category.paginate_by_sql sql, page: params[:page], per_page: PER_PAGE
    # check pagination second time with number of pages
    bad_pagination?(@categories.total_pages)
  end

  # for admins list all not public categories
  def list_no_public
    return unless access?(:admin, Category.new)

    @categories = Category.paginate_by_sql "select * from categories where public = 0", :page => params[:page],
                                                                                        :per_page => PER_PAGE
    # check pagination second time with number of pages
    bad_pagination?(@categories.total_pages)
  end

  # for admins check duplicates over the locales
  def list_duplicates
    return unless access?(:admin, Category.new)

    sql = <<-SQL
      SELECT DISTINCT t1.locale, t1.value AS v1, t3.value AS v3, t1.translatable_id AS t1, t4.value AS v4, t2.translatable_id as t2
        FROM mobility_string_translations t1
        JOIN mobility_string_translations t2
          ON t1.value = t2.value
          AND t1.locale = t2.locale
          AND t1.locale IN ('en', 'de', 'es', 'ja', 'uk')
          AND t1.translatable_id <> t2.translatable_id
          AND t1.translatable_type = 'Category'
          AND t2.translatable_type = 'Category'
          AND t1.key = 'category'
          AND t2.key = 'category'
        JOIN mobility_string_translations t3
          ON t1.translatable_id = t3.translatable_id
          AND t3.locale = 'de'
          AND t3.translatable_type = 'Category'
          AND t3.key = 'category'
        JOIN mobility_string_translations t4
          ON t2.translatable_id = t4.translatable_id
          AND t4.locale = 'de'
          AND t4.translatable_type = 'Category'
          AND t4.key = 'category'
        WHERE t1.translatable_id < t2.translatable_id
        ORDER BY t1.translatable_id, t2.translatable_id
    SQL

    page_number = params[:page].present? ? params[:page].to_i : 1
    offset = (page_number - 1) * PER_PAGE
    sql_with_pagination = "#{sql} LIMIT #{PER_PAGE} OFFSET #{offset}"
    @total_count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM (#{sql}) AS count_query").first[0].to_i
    paginated_result = ActiveRecord::Base.connection.execute(sql_with_pagination)
    @result = WillPaginate::Collection.create(page_number, PER_PAGE, @total_count) do |pager|
      pager.replace(paginated_result.to_a)
    end
    bad_pagination?(@result.total_pages)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_category
    @category = Category.find(params[:id])
  rescue
    flash[:error] = t("categories.id_does_not_exist", id: params[:id])
    render "static_pages/not_found", status: :not_found
  end

  def set_comments
    @comments = Comment.where(commentable: @category)
    @commentable_type = "Category"
    @commentable_id = @category.id
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def category_params
    permitted_params = []

    I18n.available_locales.each do |locale|
      permitted_params << "category_#{locale}".to_sym
    end

    permitted_params << :public if current_user.admin?

    params.require(:category).permit(permitted_params).merge(user_id: current_user.id)
  end
end
