class Category < ActiveRecord::Base
    validates_presence_of :category
    validates_length_of :category, :maximum=>64, :message=>"Die Kategorie kann maximal 64 Zeichen lang sein."
    validates_length_of :description, :maximum=>255, :message=>"Die Beschreibung kann maximal 255 Zeichen lang sein."
    belongs_to :user
    has_and_belongs_to_many :quotations


    # get an array of arrays with all category names and category ids for form
    def self.get_all_categories_array
        ret = []
        for e in find(:all)
            ret << [e.category, e.id]
        end
        ret
    end
	
	# count all non-public categories
	def Category.count_non_public
		return count_by_sql("select count(*) from categories where public = 0")
    end
	
	# gives an array with all categories names initial chars, e.g. ["a", "b", "d" ...]
	def Category.init_chars
		a = Category.find_by_sql "select distinct substring(upper(trim(category)) from 1 for 1) as init from categories order by init"
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
