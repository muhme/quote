class Author < ActiveRecord::Base
    has_one :quotation
    belongs_to :user
    validates_length_of :name, :maximum=>64, :message=>"Der Nachname kann maximal 64 Zeichen lang sein."
    validates_length_of :firstname, :maximum=>64, :message=>"Der Vorname kann maximal 64 Zeichen lang sein."
    validates_length_of :description, :maximum=>255, :message=>"Die Beschreibung kann maximal 255 Zeichen lang sein."
    validates_length_of :link, :maximum=>255, :message=>"Der Link kann maximal 255 Zeichen lang sein."

    # returns authors name or blank
    # returns "", "firstname", "lastname" or "firstname lastname"
    #
    def get_author_name_or_blank

        ret = ""

        ret += firstname unless firstname.blank?
        ret += " " unless firstname.blank? or name.blank?
        ret += name unless name.blank?

        ret
    end

    # returns authors name, linked if possible, or blank
    # returns "", "firstname", "lastname" or "firstname lastname"
    #
    def get_linked_author_name_or_blank

        ret = get_author_name_or_blank
        ret = "<a href=\"#{self.link}\" target=\"quote_extern\">#{ret}</a>" unless ret.blank? or self.link.blank?

        ret
    end

    # gives last name comma separated from first name
    # w/o comma if first or last name is missing
    # gives an empty string if first and last name are missing
    # e.g. gives "Einstein, Albert" or only lastname "Sokrates" or only firstname "Karl" or ""
    def last_first_name
        ret = ""

        ret += name unless name.blank?
        ret += ", " unless firstname.blank? or name.blank?
        ret += firstname unless firstname.blank?

        ret
    end

    # count all non-public authors
    def Author.count_non_public
        return count_by_sql("select count(*) from authors where public = 0")
    end

    # gives an array with all author names initial chars, e.g. ["a", "b", "d" ...]
    def Author.init_chars
        a = Author.find_by_sql "select distinct substring(upper(trim(name)) from 1 for 1) as init from authors order by init"
        ret = []
        for i in 0..(a.length-1)
            ret[i] = a[i].nil? ? '*' : a[i].attributes['init']
            # cannot use map, must use gsub for multibyte-support (from ActiveSupport::Multibyte)
            ret[i] = ret[i].gsub('Ä','A')
            ret[i] = ret[i].gsub('Ö','O')
            ret[i] = ret[i].gsub('Ü','U')
            ret[i] = ret[i].gsub('ß','s')
            ret[i] = '*' unless ('A'..'Z').include?(ret[i])
        end
        ret
    end

end
