class Quotation < ActiveRecord::Base
    validates_presence_of :quotation
    validates_uniqueness_of :quotation
    validates_length_of :quotation, :maximum=>512, :message=>"Das Zitat kann maximal 512 Zeichen lang sein."
    validates_length_of :source, :maximum=>255, :message=>"Die Original-Quelle kann maximal 255 Zeichen lang sein."
    validates_length_of :source_link, :maximum=>255, :message=>"Der Link kann maximal 255 Zeichen lang sein."
    has_and_belongs_to_many :categories
    belongs_to :user
    belongs_to :author

# hlu, Aug 21 2007: we allow unknown user ids
#    def validate
#        unless User.find_by_id user_id
#            errors.add(:user_id, "Unbekannter Benutzer-ID #{user_id}")
#        end
#    end

    # get number of categories
    def category_count
        self.categories.size
    end

	# count all non-public quotations
	def Quotation.count_non_public
		return count_by_sql("select count(*) from quotations where public = 0")
    end

    def get_author_name_or_blank

        self.author ? self.author.get_author_name_or_blank : ""
    end

    # returns authors name and source name or blank
    # returns "", "authors name", "source" or "authors name, source"
    #
    def get_author_and_source_name

        ret = get_author_name_or_blank
        ret += ", " unless ret.blank? or self.source.blank?
        ret += self.source unless self.source.blank?

        ret
    end

    # returns - with links if exist - authors name and source name or blank
    # returns "", "authors name", "source" or "authors name, source"
    #
    def get_linked_author_and_source

        my_source = self.source
        my_source = "<a href=\"#{self.source_link}\" target=\"quote_extern\">#{self.source}</a>" unless self.source.blank? or self.source_link.blank?
        ret = self.author ? self.author.get_linked_author_name_or_blank : ""
        ret += ", " unless ret.blank? or my_source.blank?
        ret += my_source unless my_source.blank?

        ret
    end

    # getter isn't generated
    #
    def category_ids

        ret = []
            for c in self.categories
                ret << c.id
            end
        ret
    end

    # generated setter doesn't work
    #
    def category_ids=(category_ids)

        # stupid removing all - but short and working
        remove_categories categories unless self.categories.empty?

        list = []
        for id in category_ids
            list << Category.find(id)
        end
        self.categories << list

    end

end
