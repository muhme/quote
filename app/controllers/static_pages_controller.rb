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
# TODO sql = "select distinct u.id from users u, quotations q where u.id = q.user_id"
#    @lines = []
#    for user_id in User.find_by_sql(sql)
#      user = User.find(user_id)
#      @lines << user.login + " (" + user.number_of_quotations.to_s + ")"
#      @lines.sort!
#    end
    # render :layout => false, :content_type => 'text/plain'
    render plain: "TEAM OK"
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

  def list
  end
  
  # routed for '*path' catch all
  def not_found
    render :status => 404
  end
end
