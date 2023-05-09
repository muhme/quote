module ApplicationHelper

  # Create a SEO page title.
  def page_title
    d = "Zitat-Service"

    if controller.controller_name == "authors"
      if controller.action_name == "list_by_letter"
        d += " –  #{t('g.authors', count: 2)}, #{t('layouts.application.starting_with_letter', letter: params[:letter].first)}"
      elsif controller.action_name == "show" and @author.present?
        d += " – #{t('g.authors', count: 1)} #{@author.get_author_name_or_blank}"
      else
        d += " – #{t('g.authors', count: 2)}"
      end
    end

    if controller.controller_name == "categories"
      if controller.action_name == "list_by_letter"
        d += " –  #{t('g.categories', count: 2)}, #{t('layouts.application.starting_with_letter', letter: params[:letter].first)}"
      elsif controller.action_name == "show" and @category.present?
        d += " – #{t('g.categories', count: 1)} #{@category.category}"
      else
        d += " – #{t('g.categories', count: 2)}"
      end
    end

    if controller.controller_name == "quotations"
      if controller.action_name == "show" and @quotation.present?
        d += " – #{t('layouts.application.quote_from')} #{@quotation.get_author_name_or_blank}"
      else
        d += " – #{t('g.quotes', count: 2)}"
        d += " #{t('g.from')} #{@author.get_author_name_or_blank}" if controller.action_name == "list_by_author" and @author.present?
        d += " #{t('g.for')} #{@category.category}" if controller.action_name == "list_by_category" and @category.present?
        d += " #{t('layouts.application.of_the_user')} #{h(params[:user])}" if controller.action_name == "list_by_user"
      end
    end

    d += " – #{t('layouts.application.not_found')}" if controller.action_name == "not_found"
    d += " – #{t('layouts.application.contact')}" if controller.action_name == "contact"
    d += " – #{t('layouts.application.project')}" if controller.action_name == "project"
    d += " – #{t('layouts.application.register')}" if controller.controller_name == "users" and controller.action_name == "new"
    d += " – #{t('layouts.application.login')}" if controller.controller_name == "user_sessions" and controller.action_name == "new"
    d += " – #{t('layouts.application.help')}" if controller.action_name == "help"
    d += " – #{t('layouts.application.use')}" if controller.action_name == "use"
    d += " – #{t('layouts.application.joomla')}" if controller.action_name == "joomla"
    d += " – #{t('layouts.application.joomla_english')}" if controller.action_name == "joomla_english"

    d += ", #{t('g.page')} #{params[:page]}" if params[:page]

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

  # gives links to the authors by 1st letter as four-rows-table
  # A B C D E F G
  # H I J K L M N
  # O P Q R S T U
  # V W X Y Z *
  def author_links locale
    init_chars = Author.init_chars
    ret = "<table id=\"letter\"><tr>"
    all = ("A".."Z").to_a
    all << "*"
    for i in 0..(all.length - 1)
      if init_chars.include?(all[i])
        ret <<= "<td>" + link_to(all[i], locale: locale, controller: :authors, action: :list_by_letter, letter: all[i]) + "</td>"
      else
        ret <<= "<td id=\"unused\">#{all[i]}</td>"
      end
      ret <<= "</tr><tr>" if ((i + 1) % 7) == 0
    end
    ret <<= "</tr></table>"
  end

  # gives links to the categories by 1st letter as four-rows-table
  # A B C D E F G
  # H I J K L M N
  # O P Q R S T U
  # V W X Y Z *
  def category_links locale
    init_chars = Category.init_chars
    ret = "<table id=\"letter\"><tr>"
    all = ("A".."Z").to_a
    all << "*"
    for i in 0..(all.length - 1)
      if init_chars.include?(all[i])
        ret <<= "<td>" + link_to(all[i], locale: locale, controller: :categories, action: :list_by_letter, letter: all[i]) + "</td>"
      else
        ret <<= "<td id=\"unused\">#{all[i]}</td>"
      end
      ret <<= "</tr><tr>" if ((i + 1) % 7) == 0
    end
    ret <<= "</tr></table>"
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
  def lh(link)
    return link_to(link[7..link.size], link, :popup => true) if link =~ /^http:\/\//i
    link_to(link[8..link.size], link, :popup => true) if link =~ /^https:\/\//i
  end

  # depending on 3rd param 'bool' if true
  #   - returns table header 'name' entry and arrow-down-image or
  #   - returns table header 'name' entry linked with 'link'
  def sorted_img_if(name, link, bool)
    bool ? name + image_tag("arrow_down.png", :alt => t('g.arrow_down'), :title => t('g.ordered'), :border => 0) + "</th>" : link
  end

  # do an html_escape() and a truncate overall on 40 chars
  # make the 1st name letter bold
  def author_name(firstname, name)
    ret = ""
    unless firstname.blank?
      ret = h(firstname)
    end
    unless name.blank?
      ret = truncate(html_escape(ret), length: 25) # to have enough space for the <b>A</b> and not truncate in tag
      ret += " " unless firstname.blank?
      ret += "<b>".html_safe + h(name[0..0]) + "</b>".html_safe + h(name[1..name.size])
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
      ret << ' <span class="example">('
      ret << sample
      ret << ')</span>'
    end
    raw(ret)
  end

  # html escape string and return <span> with given class name, or empty string if no string is present
  def raw_span_class_if_present(class_name, str)
    str.present? ? raw("<span class=\"#{class_name}\">#{h(str)}</span>") : ""
  end

  # returns e.g. "🇺🇦 UK – українська" or "🇺🇦 UK" if shorten is true for symbol :uk
  # falls back to :de for unknown locale 
  #
  def string_for_locale(locale, shorten = false)
    logger.debug { "string_for_locale(#{locale.class} #{locale}, #{shorten})" }
    locales = {
      :de => '<span class="flags">&#x1F1E9;&#x1F1EA; DE</span> – Deutsch',
      :en => '<span class="flags">&#x1F1FA;&#x1F1F8; EN</span> – English',
      :es => '<span class="flags">&#x1F1EA;&#x1F1F8; ES</span> – Español',
      :ja => '<span class="flags">&#x1F1EF;&#x1F1F5; JA</span> – 日本語',
      :uk => '<span class="flags">&#x1F1FA;&#x1F1E6; UK</span> – Українська'
    }
    locale = :de unless locales.has_key?(locale)
    ret = locales[locale]
    ret = ret.split(" – ").first if shorten
    logger.debug { "string_for_locale ret=\”#{ret}\”" }
    ret
  end

end
