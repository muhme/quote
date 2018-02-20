class AuthorController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create, :update, :destroy ],
         :redirect_to => { :action => :wrong }

    # get all public for not logged in users and
    # own entries for logged in users and all entries for admins
    def list

        sql = 'select * from authors a'
        sql += " where public = 1" if not logged_in? or self.current_user.admin != true;
        sql += ' or user_id = ?' if logged_in? and self.current_user.admin != true;
        sql += params[:order] == 'authors' ?
               # by authors name and firstname alphabeticaly
               # using select with IF to sort the empty names authores at the end
               ' order by IF(a.name="","ZZZ",a.name), a.firstname' :
               # by the number of quotations that the authors have
               ' order by (select count(*) from quotations q where q.author_id = a.id) desc'

        @authors = Author.paginate_by_sql [sql, self.current_user.id], :page=>params[:page], :per_page=>10
    end

    def list_no_public
        if ! logged_in? or ! self.current_user.admin
            flash[:error] = "Kein Administrator!"
            redirect_to :action => 'list'
            return false
        end
        @authors = Author.paginate_by_sql 'select * from authors where public = 0', :page=>params[:page], :per_page=>10
    end
	
	def list_by_letter
		letter = params[:letter]
		if letter.blank?
			flush[:error] = "Buchstabe fehlt!"
			redirect_to :action => 'list'
			return			
		end
		if letter == "*"
        	sql = "select * from authors where name NOT REGEXP '[A-Z].*'"
		else
			sql = "select * from authors where name like ?"
        end
        sql += ' order by name, firstname'
        @authors = Author.paginate_by_sql [sql, "#{letter.first}%"], :page=>params[:page], :per_page=>10
	end
	
  def show
    @author = Author.find(params[:id])
    return unless access?(@author, :read)
  end

  def new
    @author = Author.new
  end

  def create

    p = prevent_faking_parameter_public(params[:author])

    @author = Author.new(p)
    @author.user_id = self.current_user.id
    if @author.save
      flash[:notice] = "Der Autor \"#{@author.firstname} #{@author.name}\" wurde erfolgreich angelegt."
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
    rescue Exception => exc
      logger.error "author new failed: #{exc.message}"
      flash[:error] = "Das Anlegen des Autors \"#{@author.firstname} #{@author.name}\" ist gescheitert! (#{exc.message})"
      redirect_to(:action => 'new')
  end

    def edit
        @author = Author.find(params[:id])
        return unless access?(@author, :update)
    end

  def update
    @author = Author.find(params[:id])
    return unless access?(@author, :update)

    p = prevent_faking_parameter_public(params[:author])

    if @author.update_attributes(p)
      flash[:notice] = "Der Autor \"#{@author.firstname} #{@author.name}\" wurde erfolgreich ge&auml;ndert."
      redirect_to :action => 'show', :id => @author
    else
      render :action => 'edit'
    end
  end

  def destroy
    @author = Author.find(params[:id])
    return unless access?(@author, :destroy)

    @author.destroy
    flash[:notice] = "Der Autor \"#{@author.firstname} #{@author.name}\" wurde gel&ouml;scht."
    redirect_to :action => 'list'
  end

  def wrong
    flash[:error] = "Da ist etwas schiefgegangen."
    redirect_to :action => 'list'
  end

end
