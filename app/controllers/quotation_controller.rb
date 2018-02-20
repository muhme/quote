class QuotationController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create, :update, :destroy ],
         :redirect_to => { :action => :wrong}

    # get all public for not logged in users and
    # own entries for logged in users and all entries for admins
    def list

        sql_array = []
        search = ""
        search_and = ""
        pattern = params[:pattern]
        unless pattern.nil?
            search = " quotation like ? "
            search_and = " #{search} and "
        end

        if not logged_in?
            visibility = "public = 1"
        elsif self.current_user.admin == true
            visibility = ""
        else
            visibility = "( public = 1 or user_id = ? )"
        end 

        sql = 'select * from quotations'
        sql += " where #{search_and} #{visibility}" if not logged_in? or self.current_user.admin != true;
        sql += " where #{search}" if logged_in? and self.current_user.admin == true and ! pattern.nil?
        sql << " order by id desc"

        sql_array << sql
        sql_array << "%#{pattern}%" unless pattern.nil?
        sql_array << self.current_user.id if logged_in? and self.current_user.admin != true
        @quotations = Quotation.paginate_by_sql sql_array, :page=>params[:page], :per_page=>5
        
        flash.now[:notice] = 'Die Zitate sind danach sortiert, wann sie eingestellt wurden. Die zuletzt eingestellten Zitate stehen oben.' unless ( params[:page] and params[:page].to_i > 1 ) 
    end

    # select q.* from `quotations` q, categories c, categories_quotations cq where q.public = 1 and category_id = 1 and quotation_id = q.id
    def list_by_category

        @category = Category.find params[:category]

        sql = 'select distinct q.* from quotations q, categories c, categories_quotations cq where category_id = ? and quotation_id = q.id'
        if not logged_in?
            sql += " and q.public = 1"
        elsif self.current_user.admin != true
            sql += ' and ( q.public = 1 or q.user_id = ? )'
        end

        sql_array = []
        sql_array << sql
        sql_array << params[:category]
        sql_array << self.current_user.id if logged_in? and self.current_user.admin != true;
        @quotations = Quotation.paginate_by_sql sql_array, :page=>params[:page], :per_page=>5
    end

    # select * from `quotations` where q.public = 1 and author_id = ?
    def list_by_author

        @author = Author.find params[:author]

        sql = 'select * from quotations where author_id = ?'
        if not logged_in?
            sql += " and public = 1"
        elsif self.current_user.admin != true
            sql += ' and ( public = 1 or user_id = ? )'
        end

        sql_array = [sql, params[:author]]
        sql_array << self.current_user.id if logged_in? and self.current_user.admin != true;
        @quotations = Quotation.paginate_by_sql sql_array, :page=>params[:page], :per_page=>5
    end
	
    # list quotations created by a user
    def list_by_user
    	
    	user = params[:user]
		
		if user.blank?
			flash[:error] = "Kein Benutzer angegeben!"
			redirect_to :action => 'list'
			return false
		end			

        sql = ["select distinct q.* from quotations q, users u where q.user_id = u.id and u.login = ? order by q.created_at desc", user]
        @quotations = Quotation.paginate_by_sql sql, :page=>params[:page], :per_page=>5
    end	

    def list_no_public
        if ! logged_in? or ! self.current_user.admin
            flash[:error] = "Kein Administrator!"
            redirect_to :action => 'list'
            return false
        end
        @quotations = Quotation.paginate_by_sql 'select * from quotations where public = 0', :page=>params[:page], :per_page=>5
    end


  def show
    @quotation = Quotation.find(params[:id])
    return unless access?(@quotation, :read)
  end

  def new
    @quotation = Quotation.new
  end

  def create

    p = prevent_faking_parameter_public(params[:quotation])

    @quotation = Quotation.new(p)
    @quotation.user_id = self.current_user.id
    if @quotation.save
      flash[:notice] = 'Das Zitat wurde erfolgreich angelegt.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
    rescue Exception => exc
      logger.error "quotation new failed: #{exc.message}"
      flash[:error] = "Das Anlegen des Zitates ist gescheitert! (#{exc.message})"
      redirect_to :action => 'new'
  end

  def edit
    @quotation = Quotation.find(params[:id])
    return unless access?(@quotation, :update)
  end

  def update
    @quotation = Quotation.find(params[:id])
    return unless access?(@quotation, :update)

    p = prevent_faking_parameter_public(params[:quotation])

    if params[:categories]
        params[:quotation][:categories] = [ Category.find(params[:categories][:id]) ]
    end

    # a little bit dummy, we're removing all categories 1st
    @quotation.categories.delete_all

    if @quotation.update_attributes(p)
      flash[:notice] = 'Das Zitat wurde aktualisiert.'
      redirect_to :action => 'show', :id => @quotation
    else
      render :action => 'edit'
    end
  end

  def destroy
    @quotation = Quotation.find(params[:id])
    return unless access?(@quotation, :destroy)

    @quotation.destroy
    flash[:notice] = "Das Zitat wurde gel&ouml;scht."
    redirect_to :action => 'list'
  end

  def wrong
    flash[:error] = "Da ist etwas schiefgegangen."
    redirect_to :action => 'list'
  end

end
