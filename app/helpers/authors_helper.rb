module AuthorsHelper
  # returns "、", "名、",       "、名前",      "名前、名"              for :ja
  # returns ", ", "lastname,", ",firstname", "lastname, firstname" for all other locales
  def name_comma_firstname(name, firstname, locale)
    ret = ""
    ret << name.to_s
    ret << (locale == :ja ? "、" : ", ") # "、" is one character w/o space as japanese don't use spaces to separate
    ret << firstname.to_s
  end
end
