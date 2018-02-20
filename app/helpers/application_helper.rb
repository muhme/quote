# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # gives an HTML-IMG if the param has the desired value
  def sorted_img_if(name, link, bool)
    return bool ? name + image_tag("arrow_down.png", :alt => 'Sortiert', :title => 'Sortiert', :border => 0) + "</th>" : link

  end

  # do an html_escape() and a truncate() and using "&nbsp;" if the result blank
  def th(content, length)
    ret = truncate(h(content),length)
    ret.blank? ? "&nbsp;" : ret
  end

  # do an html_escape() and a truncate overall on 40 chars
  # make the 1st name letter bold
  def author_name(firstname, name)
    ret = ''
    unless firstname.blank?
      ret = (h(firstname) + " ")
    end
    unless name.blank?
      ret = truncate(h(ret),30) # to have enough space for the <b>A</b> and not truncate in tag
      # todo: fix UTF-8 two-byte handling everywhere!
      # if name[0..1] == Iconv.new('utf-8//IGNORE//TRANSLIT', 'iso-8859-15').iconv("Ä")
      if name[2..4] == "sop" and name.length == 5
        ret += "<b>" + h(name[0..1]) + "</b>" + h(name[2..name.size])
      else
        ret += "<b>" + h(name[0..0]) + "</b>" + h(name[1..name.size])
      end
      ret = truncate(ret,40)
    end
    ret
  end

  # do an html_escape() and remove "http://" and set a visible link
  def lh(link)

    link = link_to(link[7..link.size], link, :popup => true) if link =~ /^http:\/\//i

    link

  end

  # do an html_escape() and get users login name oder "" if the user doesn't exist
  def hu(id)

    User.exists?(id) ? h(User.find(id).login) : ""

  end

  # Produces e.g. "19.12.1961, 06:15 Uhr MEZ", including daylight saving time
  def nice_date(date)
    Time.zone = 'Berlin'
    date.nil? ? "" : h(Time.zone.at(date).strftime("%d.%m.%y, %H:%M Uhr %Z").gsub('CET','MEZ').gsub('CEST','MESZ'))
  end

  # Produces nice number, e.g. 1.234 instead of 1234
  # Could be replaced in RoR 3.2 with number_to_human(n, :separator => '.')
  def nice_number(number)
    return number.to_s if number < 1000
    thousend = number / 1000
    rest = number % 1000
    return "#{thousend}.#{rest}"
  end

  # hlu, Aug 28 2007
  # if a user logged in with the same id oder as admin?
  # this method have to stay here because user infos are not available in the models
  def can_edit?(user_id)
    logged_in? && ( self.current_user.id == user_id || self.current_user.admin == true )
  end

  # checks if the Quotation, Author or Category has non public entries
  def has_non_public(thisClass)
    logged_in? && self.current_user.admin && thisClass.count_non_public > 0
  end

  # gives links to the authors by 1st letter as four-rows-table
  # A B C D E F G
  # H I J K L M N
  # O P Q R S T U
  # V W X Y Z *
  def author_links
    init_chars = Author.init_chars
    ret = "<table id=\"letter\"><tr>"
    all = ('A'..'Z').to_a
    all << "*"
    for i in 0..(all.length - 1)
      if init_chars.include?(all[i])
        ret <<= "<td>" + link_to(all[i], :controller => "author", :action => "list_by_letter", :letter => all[i]) + "</td>"
      else
        ret <<= "<td id=\"unused\">#{all[i]}</td>"
      end
      ret <<= "</tr><tr>" if ((i+1) % 7) == 0
    end
    ret <<= "</tr></table>"
  end

  # gives links to the categories by 1st letter as four-rows-table
  # A B C D E F G
  # H I J K L M N
  # O P Q R S T U
  # V W X Y Z *
  def category_links
    init_chars = Category.init_chars
    ret = "<table id=\"letter\"><tr>"
    all = ('A'..'Z').to_a
    all << "*"
    for i in 0..(all.length - 1)
      if init_chars.include?(all[i])
        ret <<= "<td>" + link_to(all[i], :controller => "category", :action => "list_by_letter", :letter => all[i]) + "</td>"
      else
        ret <<= "<td id=\"unused\">#{all[i]}</td>"
      end
      ret <<= "</tr><tr>" if ((i+1) % 7) == 0
    end
    ret <<= "</tr></table>"
  end

  # converts UTF-8 String to lowercase and substitutes German umlaute to the comparable aquivalents
  # e.g. "Müller" to "mueller"
  def to_comparable(s)
    s.mb_chars.downcase.gsub(/ä/,'ae').gsub(/ö/,'oe').gsub(/ü/,'ue').gsub(/ß/,'ss')
  end

  # Create a SEO page title.
  def page_title

    d = "Zitat-Service"

    if controller.controller_name == "author"
      if controller.action_name == "list_by_letter"
        d += " - Autoren die mit " + params[:letter].first + " beginnen"
      elsif controller.action_name == "show"
        d += " - Autor " + @author.get_author_name_or_blank
      else
        d += " - Autoren"
      end
    end

    if controller.controller_name == "category"
      if controller.action_name == "show"
        d += " - Kategorie " + @category.category
      else
        d += " - Kategorien"
        d += " die mit " + params[:letter].first + " beginnen" if controller.action_name == "list_by_letter"
      end
    end

    if controller.controller_name == "quotation"
      if controller.action_name == "show"
        d += " - Zitat von " + @quotation.get_author_name_or_blank
      else
        d += " - Zitate"
        d += " von " + @author.get_author_name_or_blank if controller.action_name == "list_by_author"
        d += " zu " + @category.category if controller.action_name == "list_by_category"
        d += " des Benutzers " + h(params[:user]) if controller.action_name == "list_by_user"
      end
    end

    d += " - Fehler 404 - Eintrag nicht gefunden" if controller.action_name == "not_found"
    d += " - Impressum" if controller.action_name == "contact"
    d += " - Projekt" if controller.action_name == "project"
    d += " - Statusreport" if controller.action_name == "report"
    d += " - Anmelden" if controller.action_name == "login"
    d += " - Eintragen" if controller.action_name == "signup"
    d += " - Hier wird Dir geholfen!" if controller.action_name == "help"
    d += " - Zitate in die eigene Homepage einbinden" if controller.action_name == "use"
    d += " - Zitate mit Joomla! in die eigene Homepage einbinden" if controller.action_name == "joomla"

    d += ", Seite #{params[:page]}" if params[:page]

    d
  end
end
