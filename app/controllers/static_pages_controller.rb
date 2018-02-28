class StaticPagesController < ApplicationController
  def joomla
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
      user = User.find(user_id.id)
      @lines << user.login + " (" + user.number_of_quotations.to_s + ")"
    end
   @lines = @lines.sort_by(&:downcase)
    render :layout => false #, :content_type => 'text/plain'
    # render plain: "TEAM OK"
  end
  


  def contact
  end

  def joomla_english
  end

  def project
  end

  def use
  end

  def help
  end

  # get one random quotation
  # get last three users they have created new quotes, linked to there list of quotes and with a count of there quotes at all
  def list
  
    # select * from quotations where public = 1 order by rand() limit 1
    @quotation = Quotation.order("rand()").first

    # for inner limit see https://stackoverflow.com/questions/26372511/mysql-order-by-inside-subquery
    sql = "select distinct x.user_id from ( select q.user_id from quotations q order by created_at desc limit 1000) as x limit 0,3"
    quotations = Quotation.find_by_sql(sql)
    @users = []
    
    for i in 0..2
      if i < quotations.size
        login = ""
        begin
          user = User.find(quotations[i].user_id)
          login = user.login
        rescue
          login = "id=#{quotations[i].user_id}"
        end
        begin
          count = Quotation.count_by_sql("select count(*) from quotations where user_id = #{quotations[i].user_id}")
          @users[i] = "<a href=\"" +
                      url_for(:only_path=>true, :controller=>'quotations', :action=>'list_by_user', :user=>login) +
                      "\">#{login}</a>(#{count})"
        rescue
          @users[i] = login
        end
      else
        @users[i]=""
      end
      i = i + 1
    end
  end
  
  def search
    redirect_to :controller => 'quotation', :action => 'list', :pattern => params[:find]
  end
  
  # routed for '*path' catch all
  def not_found
    render :status => 404
  end
end
