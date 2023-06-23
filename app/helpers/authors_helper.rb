module AuthorsHelper
  # display "name, firstname" or empty string if authors name and firstname
  # is equal actual locale or not set in given locale
  def display_name_or_not(author, locale)
    localized_name = author.name(locale: locale)
    localized_firstname = author.firstname(locale: locale)

    if (localized_name == author.name && localized_firstname == author.firstname) or
       (localized_name.blank? && localized_firstname.blank?)
      ""
    else
      "#{ERB::Util.h(localized_name)}, #{ERB::Util.h(localized_firstname)}"
    end
  end

  # display link in actual locale or empty string if link
  # is equal actual locale or not set in given locale
  def display_link_in_other_locale_or_not(author, locale)
    localized_link = author.link(locale: locale)

    if (locale == I18n.locale or (localized_link != author.link and localized_link.present?))
      lh(author.link)
    else
      ""
    end
  end
end
