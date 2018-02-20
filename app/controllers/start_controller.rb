class StartController < ApplicationController
  def index
    list
    render :action => 'list'
  end

    # get one random quotation, public or from my own quotes
    # get last three users they have created new quotes, linked to there list of quotes and with a count of there quotes at all 
    def list

        sql = 'select * from quotations'
        sql += ' where public = 1' if not logged_in? or self.current_user.admin != true;
        sql += ' or user_id = ?' if (logged_in? and self.current_user.admin != true);
        sql += ' order by rand() limit 1'
        @quotation = Quotation.find_by_sql([sql, self.current_user.id])[0]
		
	
		sql = "select distinct x.user_id from ( select q.user_id from quotations q order by created_at desc) as x limit 0,3"
		quotations = Quotation.find_by_sql(sql)
		@users = []
		for i in 0..2
			if i < quotations.size
				begin
					user = User.find(quotations[i].user_id)
					login = user.login
				rescue
					login = "id=#{quotations[i].user_id}"
				end
				count = Quotation.count_by_sql("select count(*) from quotations where user_id = #{quotations[i].user_id}")
				@users[i] = "<a href=\"" +
						url_for(:only_path=>true, :controller=>'quotation', :action=>'list_by_user', :user=>login) +
						"\">#{login}</a>(#{count})"
			else
				@users[i]=""
			end
			i = i + 1
		end	
    end

    def search
      redirect_to :controller => 'quotation', :action => 'list', :pattern => params[:result][:pattern]
    end

    # dynamic generated humans.txt
    def humans
        # create alphab. sorted list of user's login name with number of quotations, like:
        # anton (4)
        # berta (17)
        # charles (1)
        # ...
		sql = "select distinct u.id from users u, quotations q where u.id = q.user_id"
        @lines = []
        for user_id in User.find_by_sql(sql)
          user = User.find(user_id)
          @lines << user.login + " (" + user.number_of_quotations.to_s + ")"
          @lines.sort!
        end
		render :layout => false, :content_type => 'text/plain'
    end

    # routed for '*whatever'
	def not_found
        render :status => 404
	end
	
	def contact
	end
	
	def error_found
	end
	
	def project
	end
	
	def help
	end	
	
	def report
	end
	
	def use
	end
	
	def joomla
	end

	def joomla_english
	end

	# fall-back if the redirect to the CGI script is missing
	def quote
		render :inline => "<?-- fall-back for missing quote.cgi rewrite --><div class=\"quote\"><div class=\"quotation\">Der Weg ist das Ziel.</div></div>"
	end

end
