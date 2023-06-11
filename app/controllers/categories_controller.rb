class CategoriesController < ApplicationController
  before_action :set_category, only: [:show, :edit, :update, :translate, :destroy]
  before_action :set_comments, only: [:show, :destroy]

  # GET /categories
  def index
    sql = <<-SQL
    SELECT DISTINCT c.* FROM categories c
      INNER JOIN mobility_string_translations mst
        ON c.id = mst.translatable_id
        AND mst.translatable_type = 'Category'
        AND mst.locale = '#{I18n.locale}'
        AND mst.key = 'category'
    SQL
    sql += " where c.public = 1" if not current_user or current_user.admin != true
    sql += " or c.user_id = #{current_user.id}" if current_user and current_user.admin != true
    sql += params[:order] == "categories" ?
    # by category name alphabeticaly
      " order by mst.value" :
    # by the number of quotations that the categories have
      " order by (select count(*) from categories_quotations cq, quotations q where cq.quotation_id = q.id and cq.category_id = c.id) desc"

    @categories = Category.paginate_by_sql(sql, page: params[:page], :per_page => PER_PAGE)
    # check pagination second time with number of pages
    bad_pagination?(@categories.total_pages)
  end

  # GET /categories/1
  def show
    return unless access?(:read, @category)

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
      logger.error "create failed with #{e}"
      return render :new, status: :unprocessable_entity
    end

    actual_locale = I18n.locale
    error_logged = false
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale.to_s) do
        if locale != actual_locale
          translated = deepl_translate(@category.category(locale: actual_locale), actual_locale, locale)
          if translated.present?
            @category.category = translated
          elsif !error_logged
            flash[:error] = t("g.machine_translation_failed")
            error_logged = true
          end
        end
      end
    end
    @category.public = current_user.admin ? params[:category][:public] : false

    if @category.save
      return redirect_to category_path(@category, locale: I18n.locale), notice: t(".created", category: @category.category)
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
      I18n.with_locale(locale.to_s) do
        if params[:translate]
          if locale == actual_locale
            @category.category = params[:category]["category_#{actual_locale}"]
          else
            translated = deepl_translate(params[:category]["category_#{actual_locale}"], actual_locale, locale)
            if translated.present?
              @category.category = translated
            elsif !error_logged
              flash[:error] = t("g.machine_translation_failed", locale: actual_locale)
              error_logged = true
            end
          end
        else
          @category.category = params[:category]["category_#{locale.to_s}"]
        end
      end
    end
    @category.public = current_user.admin ? params[:category][:public] : false

    if @category.save
      return redirect_to category_path(@category, locale: I18n.locale), notice: t(".updated", category: @category.category)
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
  # NICE only showing public or own entries to be extended like in index
  def list_by_letter
    letter = params[:letter].first.upcase
    sql = <<-SQL
    SELECT DISTINCT c.* FROM categories c
      INNER JOIN mobility_string_translations mst
        ON c.id = mst.translatable_id
        AND mst.translatable_type = 'Category'
        AND mst.locale = '#{I18n.locale.to_s}'
        AND mst.key = 'category'
      WHERE mst.value 
    SQL
    if letter == "*"
      sql << " NOT REGEXP '^[#{LETTERS}].*'"
    elsif letter =~ /[#{BY_LETTER}]/
      sql << " LIKE '#{letter}%'"
      if I18n.locale == :ja
        # looking additional for corresponding katakana, dakuten and handakuten
        HIRAGANA.each_with_index do |hiragana, index|
          if hiragana == letter
            if KATAKANA[index].present?
              sql << " OR mst.value LIKE '#{KATAKANA[index]}%'"
            end
            if HIRAGANA_DAKUTEN[index].present?
              sql << " OR mst.value LIKE '#{HIRAGANA_DAKUTEN[index]}%'"
            end
            if HIRAGANA_HANDAKUTEN[index].present?
              sql << " OR mst.value LIKE '#{HIRAGANA_HANDAKUTEN[index]}%'"
            end
            if KATAKANA_DAKUTEN[index].present?
              sql << " OR mst.value LIKE '#{KATAKANA_DAKUTEN[index]}%'"
            end
            if KATAKANA_HANDAKUTEN[index].present?
              sql << " OR mst.value LIKE '#{KATAKANA_HANDAKUTEN[index]}%'"
            end
            break
          end
        end
      end
    else # needed to be hanlded here, as route restrictions constraints not trivial working with UTF8
      flash[:error] = t(".letter_missing")
      render "static_pages/not_found", status: :not_found
      return
    end
    sql << " ORDER BY mst.value"
    @categories = Category.paginate_by_sql sql, page: params[:page], per_page: PER_PAGE
    # check pagination second time with number of pages
    bad_pagination?(@categories.total_pages)
  end

  # for admins list all not public categories
  def list_no_public
    return unless access?(:admin, Category.new)

    @categories = Category.paginate_by_sql "select * from categories where public = 0", :page => params[:page], :per_page => PER_PAGE
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
