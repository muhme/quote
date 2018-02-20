class CategoryController < ApplicationController

# GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
verify :method => :post, :only => [ :create, :update, :destroy ],
       :redirect_to => { :action => :wrong }

    def index
        list
        render :action => 'list'
    end

    # get all public for not logged in users and
    # own entries for logged in users and all entries for admins
    def list
        sql = 'select * from categories c'
        sql += ' where  c.public = 1' if not logged_in? or self.current_user.admin != true
        sql += ' or c.user_id = ?' if (logged_in? and self.current_user.admin != true)
        sql += params[:order] == 'categories' ?
               # by category name alphabeticaly
               ' order by c.category' :
               # by the number of quotations that the categories have
               ' order by (select count(*) from categories_quotations cq, quotations q where cq.quotation_id = q.id and cq.category_id = c.id) desc'

        @categories = Category.paginate_by_sql [sql, self.current_user.id], :page=>params[:page], :per_page=>10
    end

    def list_no_public
        if ! logged_in? or ! self.current_user.admin
            flash[:error] = "Kein Administrator!"
            redirect_to :action => 'list'
            return false
        end
        @categories = Category.paginate_by_sql 'select * from categories where public = 0', :page=>params[:page], :per_page=>10
    end

	def list_by_letter
		letter = params[:letter]
		if letter.blank?
			flush[:error] = "Buchstabe fehlt!"
			redirect_to :action => 'list'
			return			
		end
		if letter == "*"
        	sql = "select * from categories where category NOT REGEXP '[A-Z].*'"
		else
			sql = "select * from categories where category like ?"
        end
        sql += ' order by category'
        @categories = Category.paginate_by_sql [sql, "#{letter.first}%"], :page=>params[:page], :per_page=>10
	end
			
    def show
        @category = Category.find(params[:id])
        return unless access?(@category, :read)
    end

    def new
        @category = Category.new
    end

  def create

    p = prevent_faking_parameter_public(params[:category])

    @category = Category.new(p)
    @category.user_id = self.current_user.id
    
    if @category.save
      flash[:notice] = "Die Kategorie \"#{@category.category}\" wurde erfolgreich angelegt."
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
    rescue Exception => exc
      logger.error "category new failed: #{exc.message}"
      flash[:error] = "Das Anlegen der Kategorie \"#{@category.category}\" ist gescheitert! (#{exc.message})"
      redirect_to :action => 'new'
  end

  def edit
    @category = Category.find(params[:id])
    return unless access?(@category, :update)
  end

  def update
    @category = Category.find(params[:id])
    return unless access?(@category, :update)

    p = prevent_faking_parameter_public(params[:category])

    if @category.update_attributes(p)
      flash[:notice] = "Die Kategorie \"#{@category.category}\" wurde erfolgreich aktualisiert."
      redirect_to :action => 'show', :id => @category
    else
      render :action => 'edit'
    end
  end

  def destroy
    @category = Category.find(params[:id])
    return unless access?(@category, :destroy)

    @category.destroy
    flash[:notice] = "Die Kategorie \"#{@category.category}\" wurde gel&ouml;scht."
    redirect_to :action => 'list'
  end

  def wrong
    flash[:error] = "Da ist etwas schiefgegangen."
    redirect_to :action => 'list'
  end

end
