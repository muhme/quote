module ApplicationHelper
    
  # Produces nice number, e.g. 1.234 instead of 1234
  def nice_number(number)
    return number.to_s if number < 1000
    thousend = number / 1000
    rest = number % 1000
    return "#{thousend}.#{rest}"
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
  
  # do an html_escape() and remove "http://" and set a visible link
  def lh(link)
    link_to(link[7..link.size], link, :popup => true) if link =~ /^http:\/\//i
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
      # todo: fix UTF-8 two-byte handling everywhere!
      # if name[0..1] == Iconv.new('utf-8//IGNORE//TRANSLIT', 'iso-8859-15').iconv("Ä")
      if name[2..4] == "sop" and name.length == 5
        ret += "<b>".html_safe + h(name[0..1]) + "</b>".html_safe + h(name[2..name.size])
      else
        ret += "<b>".html_safe + h(name[0..0]) + "</b>".html_safe + h(name[1..name.size])
      end
    end
    truncate(ret, length: 40, escape: false)
  end
  
end