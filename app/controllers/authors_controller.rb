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

    if !author_deepl_translate(actual_locale)
      flash[:error] = t("g.machine_translation_failed", locale: actual_locale)
    end

    if @author.save
      return redirect_to author_path(@author, locale: I18n.locale),
                         notice: t(".created", author: @author.get_author_name_or_blank)
    else
      render :new, status: :unprocessable_entity
    end

    # NICE give warning if the same autor already exists
  rescue Exception => exc
    problem = "#{exc.class} #{exc.message}"
    logger.error "create author failed: #{problem}"
    flash[:error] = t(".failed", author: @author.get_author_name_or_blank, exception: problem)
    render :new, status: :unprocessable_entity
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
      if !author_deepl_translate(actual_locale)
        flash[:error] = t("g.machine_translation_failed", locale: actual_locale)
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

  # Der Text wurde geschrieben von dem Autor Johann Wolfgang von Goethe.
  # The text was written by the author Johann Wolfgang von Goethe.
  # El texto fue escrito por el autor Johann Wolfgang von Goethe.
  # 著者はヨハン・ヴォルフガング・フォン・ゲーテ。
  # Текст написаний автором Йоганном Вольфгангом фон Гете.
  TRANSLATE_NAME = {
    de: ["Der Text wurde geschrieben von dem Autor mit dem Namen °°°.",
         "Der Text wurde von einem Autor namens °°° geschrieben.",
         "Der Text wurde von einem Autor mit dem Namen °°° geschrieben.",
         "Es wurde von einem Autor namens Thomas Mann geschrieben."],
    en: ["The text was written by the author with the name °°°."],
    es: ["El texto fue escrito por un autor llamado °°°.",
         "El texto fue escrito por el autor llamado °°°."],
    ja: ["°°°という作家が書いた文章だ。",
         "°°°という作家が書いたものだ。",
         "この文章°°°という作家によって書かれた。"],
    uk: ["Текст був написаний автором на ім'я °°°."],
  }.freeze

  # translates authors name, first name and description
  # can throw DeepL::Exception
  # returns true on success, else false
  def author_deepl_translate(src_locale, author = @author)
    dst_locales = I18n.available_locales - [src_locale]
    src_deleminator = src_locale == :ja ? "・" : " "
    if ENV["DEEPL_API_KEY"].present?
      begin
        text = TRANSLATE_NAME[src_locale][0].gsub("°°°", first_last_or_both(author, src_deleminator))
        dst_locales.each do |dst_locale|
          # description
          if (author.description.present?)
            ret = deepl_translate_words(author.description, src_locale.to_s.upcase, dst_locale.to_s.upcase)
          else
            ret = ""
          end
          author.send("description_#{dst_locale}=", ret)
          # firstname and name
          ret = DeepL.translate(text, src_locale.to_s.upcase, dst_locale.to_s.upcase).to_s
          logger.debug { "translated #{src_locale} \”#{text}\" -> #{dst_locale} \"#{ret}\"" }
          # "Текст був написаний автором Томасом Чендлером Галібартоном (Thomas Chandler Haliburton)."
          ret = ret.gsub(/\s?\(.*?\)/, '') # delete space + round brackets with the content inside
          found = false
          TRANSLATE_NAME[dst_locale].each do |e|
            pattern = Regexp.new(e.gsub("°°°", "([^.。]+)").gsub(".", "\\."))
            if (match = ret.match(pattern))
              found = match[1].split(/ |・/)
              mode = names_mode(author)
              if mode == :both
                author.send("name_#{dst_locale}=", found.pop)
                author.send("firstname_#{dst_locale}=", found.join(dst_locale == :ja ? "・" : " "))
                logger.debug {
                  "#{dst_locale} firstname=[#{author.firstname(locale: dst_locale)}] name=[#{author.name(locale: dst_locale)}]"
                }
              elsif mode == :firstname
                author.send("firstname_#{dst_locale}=", match[1])
                logger.debug { "#{dst_locale} firstname=[#{author.firstname(locale: dst_locale)}]" }
              elsif mode == :name
                author.send("name_#{dst_locale}=", match[1])
                logger.debug { "#{dst_locale} name=[#{author.name(locale: dst_locale)}]" }
              end
              found = true
              break # done
            end
          end
          if (found == false)
            logger.warn { "translation was not matching #{src_locale} \”#{text}\" -> #{dst_locale} \"#{ret}\"" }
            # translate without context
            ["name", "firstname"].each do |attr|
              value = author.send(attr)
              if value.present?
                ret = deepl_translate_words(value, src_locale.to_s.upcase, dst_locale.to_s.upcase)
                author.send("#{attr}_#{dst_locale}=", ret)
                logger.debug { "#{dst_locale} #{attr}=[#{ret}]" }
              end
            end
          end
        end
        return true
      rescue DeepL::Exceptions::Error => exc
        logger.error "DeepL translation failed #{exc.class} #{exc.message}"
      end
    else
      logger.warn("DEEPL_API_KEY environment is missing, no DeepL translation")
    end
    return false
  end

  def first_last_or_both(author, src_deleminator)
    return "#{author.firstname}#{src_deleminator}#{author.name}" if author.firstname.present? and author.name.present?
    return author.firstname if author.firstname.present?
    return author.name if author.name.present?

    return ""
  end

  def names_mode(author)
    return :both if author.firstname.present? and author.name.present?
    return :firstname if author.firstname.present?
    return :name if author.name.present?

    return ""
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
end
