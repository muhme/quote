module ApplicationHelper
    
  # Produces nice number, e.g. 1.234 instead of 1234
  # Could be replaced in RoR 3.2 with number_to_human(n, :separator => '.')
  def nice_number(number)
    return number.to_s if number < 1000
    thousend = number / 1000
    rest = number % 1000
    return "#{thousend}.#{rest}"
  end
  
  def logged_in?
    return nil
  end
  def has_non_public(o)
    return nil
  end
  def can_edit?(o)
    return true
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
  
  # Produces e.g. "19.12.1961, 06:15 Uhr MEZ", including daylight saving time
  def nice_date(date)
    Time.zone = 'Berlin'
    date.nil? ? "" : h(Time.zone.at(date).strftime("%d.%m.%y, %H:%M Uhr %Z").gsub('CET','MEZ').gsub('CEST','MESZ'))
  end
  
  # do an html_escape() and get users login name oder "" if the user doesn't exist
  def hu(id)

    User.exists?(id) ? h(User.find(id).login) : ""

  end

end