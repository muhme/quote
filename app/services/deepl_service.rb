# collection of all DeepL API requests and helper methods
#
class DeeplService
  # translates one word (e.g. category) or some words (e.g. author description)
  # returns translated string and can throw DeepL::Exception
  def translate_words(text, source_lang, target_lang)
    if ENV["DEEPL_API_KEY"].present?
      begin
        source = source_lang.to_s.upcase
        target = target_lang.to_s.upcase
        ret = DeepL.translate(text, source, target).to_s
        Rails.logger.debug { "translated #{source} \"#{text}\" -> #{target} \"#{ret}\"" }
        return wash_translation(ret, target_lang)
      rescue DeepL::Exceptions::Error => exc
        Rails.logger.warn { "DeepL translation failed #{exc.class} #{exc.message} \”#{text}\" #{source}->#{target}" }
      end
    else
      Rails.logger.warn { "DEEPL_API_KEY environment is missing, no DeepL translation" }
    end
    nil
  end

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
         "この文章は、°°°という作家によって書かれた。",
         "この文章°°°という作家によって書かれた。"],
    uk: ["Текст був написаний автором на ім'я °°°."],
  }.freeze

  # always translates authors description
  # only translates authors name and first name if nil
  # if authors firstname and name to be translated try is first with prompt (additional context), if this fails simple translate 1:1
  # can throw DeepL::Exception
  # returns true on success, else false
  def author_translate(src_locale, author)
    return false unless ENV["DEEPL_API_KEY"].present?

    begin
      (I18n.available_locales - [src_locale]).each do |dst_locale|
        # always translate description
        author.send("description_#{dst_locale}=", translate_description(author, src_locale, dst_locale))

        if author.firstname(locale: dst_locale).blank? or author.name(locale: dst_locale).blank?
          src_deleminator = src_locale == :ja ? "・" : " "
          text = TRANSLATE_NAME[src_locale][0].gsub("°°°", first_last_or_both(author, src_deleminator))
          found = translate_name_and_firstname(author, text, src_locale, dst_locale)

          unless found
            Rails.logger.warn { "translation was not matching #{src_locale} \”#{text}\" -> #{dst_locale}" }
            # translate without context
            fallback_translation(author, src_locale, dst_locale)
          end
        end
      end
      true
    rescue DeepL::Exceptions::Error => exc
      Rails.logger.error "DeepL translation failed #{exc.class} #{exc.message}"
      false
    end
  end

  private

  # return :both, :firstname, :name or ""
  # depending firstname and name are present, only firstname, only name or nothing
  def names_mode(author)
    return :both      if author.firstname.present? and author.name.present?
    return :firstname if author.firstname.present?
    return :name      if author.name.present?

    return ""
  end

  # translate author.description
  def translate_description(author, src_locale, dst_locale)
    if author.description.present?
      translate_words(author.description, src_locale, dst_locale)
    else
      nil
    end
  end

  # translate author.name and author.firstname
  # using text in TRANSLATE_NAME format and scan result from list of TRANSLATE_NAME formats
  def translate_name_and_firstname(author, text, src_locale, dst_locale)
    ret = DeepL.translate(text, src_locale.to_s.upcase, dst_locale.to_s.upcase).to_s
    Rails.logger.debug { "translated #{src_locale} \”#{text}\" -> #{dst_locale} \"#{ret}\"" }

    # "Текст був написаний автором Томасом Чендлером Галібартоном (Thomas Chandler Haliburton)."
    ret = ret.gsub(/\s?\(.*?\)/, '') # delete space + round brackets with the content inside
    TRANSLATE_NAME[dst_locale].each do |e|
      pattern = Regexp.new(e.gsub("°°°", "([^.。]+)").gsub(".", "\\."))
      if (match = ret.match(pattern))
        set_author_names(author, match[1], dst_locale)
        return true
      end
    end
    false
  end

  # set author.name and author.firstname if exist in match
  def set_author_names(author, match, dst_locale)
    found = match.split(/ |・/)
    mode = names_mode(author)
    if mode == :both
      author.send("name_#{dst_locale}=", found.pop)
      author.send("firstname_#{dst_locale}=", found.join(dst_locale == :ja ? "・" : " "))
      Rails.logger.debug {
        "#{dst_locale} firstname=[#{author.firstname(locale: dst_locale)}] name=[#{author.name(locale: dst_locale)}]"
      }
    elsif mode == :firstname
      author.send("firstname_#{dst_locale}=", match)
      Rails.logger.debug { "#{dst_locale} firstname=[#{author.firstname(locale: dst_locale)}]" }
    elsif mode == :name
      author.send("name_#{dst_locale}=", match)
      Rails.logger.debug { "#{dst_locale} name=[#{author.name(locale: dst_locale)}]" }
    end
  end

  # translate author.name and author.firstname 1:1 (without context)
  def fallback_translation(author, src_locale, dst_locale)
    ["name", "firstname"].each do |attr|
      value = author.send(attr)
      if value.present?
        ret = translate_words(value, src_locale.to_s.upcase, dst_locale.to_s.upcase)
        author.send("#{attr}_#{dst_locale}=", ret)
        Rails.logger.debug { "#{dst_locale} #{attr}=[#{ret}]" }
      end
    end
  end

  # returns authors:
  #   "firstname name" (src_deleminator is " ")
  #   "firstname"
  #   "name"
  #   ""
  def first_last_or_both(author, src_deleminator)
    return "#{author.firstname}#{src_deleminator}#{author.name}" if author.firstname.present? and author.name.present?
    return author.firstname if author.firstname.present?
    return author.name if author.name.present?

    return ""
  end

  # Define year-born-notation for different locales
  BORN = {
    de: "(* 0000)",
    en: "(born 0000)",
    es: "(n. 0000)",
    ja: "(0000生)",
    uk: "(нар. 0000)"
  }.freeze
  # translate year born and fix some single wrong characters from Deepl
  def wash_translation(ret, target_lang)
    # Українська translation has often a dot in the end
    ret.chomp!(".")
    # Українська translation has sometimes double quote in the beginning
    ret.sub!(/"/, "")
    # one time seen, 日本語 translation added japanese dot in the end
    ret.sub!(/。/, "")

    # (*1961) etc, see BORN
    match = ret.match(/(.*)\([^\d]*(\d{4})[\d]*\)$/)
    if match
      ret = match[1] ? match[1] : ""
      ret << BORN[target_lang.downcase.to_sym]
      ret.gsub!("0000", match[2])
    end
    ret
  end
end
