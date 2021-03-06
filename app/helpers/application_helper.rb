module ApplicationHelper

  # Create a SEO page title.
  def page_title

    d = "Zitat-Service"

    if controller.controller_name == "authors"
      if controller.action_name == "list_by_letter"
        d += " - Autoren die mit " + params[:letter].first + " beginnen"
      elsif controller.action_name == "show"
        d += " - Autor " + @author.get_author_name_or_blank
      else
        d += " - Autoren"
      end
    end

    if controller.controller_name == "categories"
      if controller.action_name == "show"
        d += " - Kategorie " + @category.category
      else
        d += " - Kategorien"
        d += " die mit " + params[:letter].first + " beginnen" if controller.action_name == "list_by_letter"
      end
    end

    if controller.controller_name == "quotations"
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
    d += " - Anmelden" if controller.controller_name == "user_sessions" and controller.action_name == "new"
    d += " - Eintragen" if controller.action_name == "signup"
    d += " - Hier wird Dir geholfen!" if controller.action_name == "help"
    d += " - Zitate in die eigene Homepage einbinden" if controller.action_name == "use"
    d += " - Zitate mit Joomla! in die eigene Homepage einbinden" if controller.action_name == "joomla"
    d += " - Using quotes with Joomla! for the own homepage" if controller.action_name == "joomla_english"

    d += ", Seite #{params[:page]}" if params[:page]

    d
  end  

  # gives nice number in singular or plural
  # e.g. "0 Zitate", "1 Zitat", "2 Zitate", "4.711 Zitate"
  def nnsp(number, singular, plural)
    return nice_number(number) + ' ' + ( number == 1 ? singular : plural )
  end
  
  # Produces nice number, e.g. 1.234 instead of 1234
  def nice_number(number)
    return number.to_s if number < 1000
    number.to_s.reverse.scan(/\d{1,3}/).join(".").reverse
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
        ret <<= "<td>" + link_to(all[i], :controller => "authors", :action => "list_by_letter", :letter => all[i]) + "</td>"
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
        ret <<= "<td>" + link_to(all[i], :controller => "categories", :action => "list_by_letter", :letter => all[i]) + "</td>"
      else
        ret <<= "<td id=\"unused\">#{all[i]}</td>"
      end
      ret <<= "</tr><tr>" if ((i+1) % 7) == 0
    end
    ret <<= "</tr></table>"
  end
  
  # Produces e.g. "19.12.1961, 06:15 Uhr MEZ", including daylight saving time
  def nice_date(date)
    Time.zone = 'Berlin'
    date.nil? ? "" : h(Time.zone.at(date).strftime("%d.%m.%Y, %H:%M Uhr %Z").gsub('CET','MEZ').gsub('CEST','MESZ'))
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

  # gives an HTML-IMG if the param has the desired value
  def sorted_img_if(name, link, bool)
    return bool ? name + image_tag("arrow_down.png", :alt => 'Sortiert', :title => 'Sortiert', :border => 0) + "</th>" : link
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
    link_to(url, '/joomla/' + url)
  end
  
end
