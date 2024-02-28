module ApplicationHelper
  # Create a SEO page title.
  def page_title
    d = "Zitat-Service"

    if controller.controller_name == "authors"
      if controller.action_name == "list_by_letter"
        d += " –  #{t("g.authors",
                      count: 2)}, #{t("layouts.application.starting_with_letter", letter: params[:letter].first)}"
      elsif controller.action_name == "show" and @author.present?
        d += " – #{t("g.authors", count: 1)} #{@author.get_author_name_or_blank}"
      else
        d += " – #{t("g.authors", count: 2)}"
      end
    end

    if controller.controller_name == "categories"
      if controller.action_name == "list_by_letter"
        d += " – #{t("g.categories",
                     count: 2)}, #{t("layouts.application.starting_with_letter", letter: params[:letter].first)}"
      elsif controller.action_name == "show" and @category.present?
        d += " – #{t("g.categories", count: 1)} #{@category.category}"
      else
        d += " – #{t("g.categories", count: 2)}"
      end
    end

    if controller.controller_name == "quotations"
      if controller.action_name == "show" and @quotation.present?
        d += " – #{t("layouts.application.quote_from")} #{@quotation.get_author_name_or_blank}"
      else
        d += " – #{t("g.quotes", count: 2)}"
        if controller.action_name == "list_by_author" and @author.present?
          d += " #{t("g.from")} #{@author.get_author_name_or_blank}"
        elsif controller.action_name == "list_by_category" and @category.present?
          d += " #{t("g.for")} #{@category.category}"
        elsif controller.action_name == "list_by_user"
          d += " #{t("layouts.application.of_the_user")} #{hu(params[:user])}"
        end
      end
    end

    if controller.action_name == "not_found"
      d += " – #{t("layouts.application.not_found")}"
    elsif controller.action_name == "contact"
      d += " – #{t("layouts.application.contact")}"
    elsif controller.action_name == "project"
      d += " – #{t("layouts.application.project")}"
    elsif controller.action_name == "help"
      d += " – #{t("layouts.application.help")}"
    elsif controller.action_name == "use"
      d += " – #{t("layouts.application.use")}"
    elsif controller.action_name == "joomla"
      d += " – #{t("layouts.application.joomla")}"
    elsif controller.action_name == "joomla_english"
      d += " – #{t("layouts.application.joomla_english")}"
    elsif controller.action_name == "new" && controller.controller_name == "users"
      d += " – #{t("layouts.application.register")}"
    elsif controller.action_name == "new" && controller.controller_name == "user_sessions"
      d += " – #{t("layouts.application.login")}"
    end

    d += ", #{t("g.page")} #{params[:page]}" if params[:page]

    d
  end

  # Produces nice number, e.g. 1.234 instead of 1234
  # TODO: replace with I18N
  def nice_number(number)
    return number.to_s if number < 1000

    number.to_s.reverse.scan(/\d{1,3}/).join(".").reverse
  end

  # return authors "name, firstname, description" or "" for unknown author (id=0) or id isn't set
  # e.g. "Schiller, Friedrich, deutscher Dichter und Philosoph (1759 - 1805)" with max length 80
  def author_selected_name(id)
    long_name = ""
    if id
      author = Author.find(id)
      [author.name, author.firstname, author.description].each do |field|
        long_name << ", " if long_name.present? and field.present?
        long_name << field if field.present?
      end
    end
    long_name[0, 80]
  end

  # gives links to the authors by 1st letter as table
  # e.g. for :en
  #   A B C D E F G H I
  #   J K L M N O P Q R
  #   S T U V W X Y Z *
  #
  def author_links
    init_chars = Author.init_chars
    all = BASE_LETTERS[I18n.locale].dup
    if I18n.locale == :ja
      all[-3] = "*" # use a not used letter place, to save one more line
    else
      all << "*"
    end
    ret = "<table id=\"letter\"><tr>"
    for i in 0..(all.length - 1)
      if init_chars.include?(all[i])
        ret << "<td>" + link_to(all[i], controller: :authors, action: :list_by_letter, letter: all[i]) + "</td>"
      else
        ret << "<td id=\"unused\">#{all[i]}</td>"
      end
      ret << "</tr><tr>" if ((i + 1) % (I18n.locale == :ja ? 5 : 9)) == 0
    end
    ret << "</tr></table>"
  end

  # gives links to the categories by 1st letter as table
  # e.g. for :en
  #   A B C D E F G H I
  #   J K L M N O P Q R
  #   S T U V W X Y Z *
  #
  def category_links
    init_chars = Category.init_chars
    all = BASE_LETTERS[I18n.locale].dup
    if I18n.locale == :ja
      all[-3] = "*" # use a not used letter place, to save one more line
    else
      all << "*"
    end
    ret = "<table id=\"letter\"><tr>"
    for i in 0..(all.length - 1)
      if init_chars.include?(all[i])
        ret << "<td>" + link_to(all[i], controller: :categories, action: :list_by_letter, letter: all[i]) + "</td>"
      else
        ret << "<td id=\"unused\">#{all[i]}</td>"
      end
      ret << "</tr><tr>" if ((i + 1) % (I18n.locale == :ja ? 5 : 9)) == 0
    end
    ret << "</tr></table>"
  end

  # TODO: replace with I18N
  # Produces e.g. "19.12.1961, 06:15 Uhr MEZ", including daylight saving time
  def nice_date(date)
    Time.zone = "Berlin"
    date.nil? ? "" : h(Time.zone.at(date).strftime("%d.%m.%Y, %H:%M Uhr %Z").gsub("CET", "MEZ").gsub("CEST", "MESZ"))
  end

  # do an html_escape() and get users login name oder "" if the user doesn't exist
  def hu(id)
    User.exists?(id) ? h(User.find(id).login) : ""
  end

  # do an html_escape() and a truncate() and using "&nbsp;" if the result blank
  def th(content, length)
    ret = truncate(html_escape(content), length: length)
    ret.blank? ? "&nbsp;" : ret
  end

  # do an html_escape() and remove "http://" or "https://" and set a visible link
  # return nil is not a link (starting with http:// or https://)
  def lh(link)
    return link_to(link[8..link.size], link, :popup => true) if link =~ /^https:\/\//i
    return link_to(link[7..link.size], link, :popup => true) if link =~ /^http:\/\//i
  end

  # depending on 3rd param 'bool' if true
  #   - returns table header 'name' entry and arrow-down-image or
  #   - returns table header 'name' entry linked with 'link'
  def sorted_img_if(name, link, bool)
    bool ? name + image_tag("arrow_down.png", :alt => t("g.arrow_down"), :title => t("g.ordered"),
                                              :border => 0) + "</th>" : link
  end

  # do an html_escape() and a truncate overall on 40 chars
  # make the 1st (last)name letter bold
  # having (last)name・firstname for :ja and "firstname name" for others
  def author_name(firstname, name, locale = I18n.locale)
    ret = ""
    # "<b>G</b>oethe"
    bold_name = "<b>".html_safe + h(name[0..0]) + "</b>".html_safe + h(name[1..name.size]) unless name.blank?

    if locale == :ja
      ret = bold_name if bold_name
      unless firstname.blank?
        ret += t('g.name_seperator', locale: locale) unless ret.blank?
        ret += firstname
      end
    else
      ret = h(firstname) unless firstname.blank?
      unless bold_name.blank?
        ret = truncate(html_escape(ret), length: 25) # to have enough space for the <b>A</b> and not truncate in tag
        ret += t('g.name_seperator', locale: locale) unless ret.blank?
        ret += bold_name
      end
    end
    truncate(ret, length: 40, escape: false)
  end

  # link to zip's in public/joomla
  def link_to_joomla(url)
    link_to(url, "/joomla/" + url)
  end

  # return last git checkin date, like "Sun Feb 5 17:58:03 2023 +0100"
  def getGitVersion
    @@gitVersion ||= `git log -1 --format=%cd`
  end

  # own SQL sanitizer as sanitize_sql_like does nothing for comments (--) and apostroph (')
  def my_sql_sanitize(str)
    str = str.gsub("--", "\\-\\-") # SQL comment
    str = str.gsub("%", "\\%")     # wildcard in searching
    str = str.gsub("_", "\\_")     # single char
    str = str.gsub("\[", "\\\[")   # open bracket
    str = str.gsub("\]", "\\\]")   # close bracket
    str = str.gsub("'", "\\'")     # apostroph
    str = str.gsub("\"", "\\\"")   # quotation marks
    str = str.gsub("\\", "\\\\")   # backslash self
    str
  end

  # create form label and description
  # e.g. 'Nachname <span class="example">z.B. Goethe</span>'
  def label_and_description(name, sample = nil)
    ret = name.dup
    if sample.present?
      ret << ' <span class="example">'
      ret << sample
      ret << "</span>"
    end
    raw(ret)
  end

  # html escape string and return <span> with given class name, or empty string if no string is present
  def raw_span_class_if_present(class_name, str)
    str.present? ? raw("<span class=\"#{class_name}\">#{h(str)}</span>") : ""
  end

  # returns e.g.
  #   "🇺🇦 UK – українська" for string_for_locale(:uk)
  #   "🇺🇦 UK" for string_for_locale(:uk, true)
  #   "🇺🇦" for string_for_locale(:uk, true, true)
  # falls back to :en for unknown locale or nil
  def string_for_locale(locale = "en", shorten = false, only_flag = false)
    # logger.debug { "string_for_locale(#{locale.class} #{locale}, #{shorten})" }
    flag = {
      :de => '&#x1F1E9;&#x1F1EA;',
      :en => '&#x1F1FA;&#x1F1F8;',
      :es => '&#x1F1EA;&#x1F1F8;',
      :ja => '&#x1F1EF;&#x1F1F5;',
      :uk => '&#x1F1FA;&#x1F1E6;'
    }.freeze
    lang = {
      :de => 'Deutsch',
      :en => 'English',
      :es => 'Español',
      :ja => '日本語',
      :uk => 'Українська'
    }.freeze
    l = locale&.to_sym&.downcase
    l = :en unless flag.has_key?(l)
    return flag[l] if only_flag

    ret = "<span class=\"flags\">#{flag[l]}&nbsp;#{l.upcase}</span>"
    ret = "#{ret} – #{lang[l]}" unless shorten
    # logger.debug { "string_for_locale ret=\”#{ret}\”" }
    ret
  end

  # returns next locale from [:de, :en, :es, :ja, :uk] as string
  def next_locale(current_locale = nil)
    locales = I18n.available_locales
    return "de" if current_locale.nil?

    # find the index of the current locale in the array, increment it by one to get the index of the next locale,
    # and then use the modulo operator (%) to ensure that the result is wrapped around to the beginning of the array
    # if it exceeds the array's length.
    index = locales.index(current_locale.to_sym)
    locales[(index + 1) % locales.length].to_s
  end

  # give I18n.available_locales with first actual or given locale
  def ordered_locales(locale = I18n.locale)
    # duplicate before manipulating
    locales = I18n.available_locales.dup

    # return the original locales if the locale is not in the list
    return locales unless locales.include?(locale)

    # remove the given locale inside the list and place at the beginning
    locales.prepend(locales.delete(locale))
  end

  # transform "Einstein:https://www.zitat-service.de/authors/20" in relative HTML link and
  # disabling turbo to force full page load as '<a href="/authors/20" data-turbo="false">Einstein</a>'#
  # and do html_escape to have a save string directly to display
  #
  def transformLink(str)
    logger.debug { "transformLink <- \”#{str}\”" }
    base_url = "https://www.zitat-service.de"

    # Step 1: Split string into array on white spaces
    parts = str.split("\s")

    # Step 2: Handle every non-white-space part and check for link transformation
    parts.map! do |part|
      if part =~ /([^:]+):(#{Regexp.quote(base_url)}([\w\/]+))/
        # if part matches link pattern, transform it into a relative link with disabling Turbo to have full page load
        "<a href=\"#{$3}\" data-turbo=\"false\">#{$1}</a>"
      else
        # Step 3: Transform for all HTML chars like < > & " to &lt; ...
        ERB::Util.html_escape(part)
      end
    end

    # Step 4: Concatenate all to one string and mark it as html_safe
    ret = parts.join(" ").html_safe
    logger.debug { "transformLink -> \”#{ret}\”" }
    ret
  end
end
