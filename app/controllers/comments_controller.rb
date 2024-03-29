class CommentsController < ApplicationController
  include ActionView::Helpers::TextHelper # for truncate()
  before_action :set_comment, only: [:edit, :update, :destroy]

  # GET /comments only for admins
  def index
    if !current_user or current_user.admin == false
      flash[:error] = t("g.no_admin")
      render "static_pages/forbidden", status: :forbidden
      return false
    end
    @comments = Comment.paginate_by_sql "select * from comments order by updated_at desc", :page => params[:page],
                                                                                           :per_page => 10
    # check pagination second time with number of pages
    bad_pagination?(@comments.total_pages)
  end

  # POST /comments/new
  def create
    return unless logged_in? t("comments.login_missing")

    @comment = Comment.new(comment_params)
    @comment.user_id = current_user.id
    @commentable_type = @comment.commentable_type
    @commentable_id = @comment.commentable_id
    @comments = Comment.where(commentable_type: @commentable_type, commentable_id: @commentable_id)

    respond_to do |format|
      if @comment.save
        format.turbo_stream
        format.html {
          redirect_to controller: @commentable_type.downcase.pluralize, action: "show", locale: I18n.locale,
                      id: @commentable_id
        }
      else
        if @comment.errors.any?
          error = t("g.error", count: @comment.errors.count)
          @comment.errors.each do |message|
            error << ". #{message.full_message}!"
          end
        end
        logger.error "comment.save FAILED with #{error}"
        format.turbo_stream
        format.html {
          flash[:error] = error
          redirect_to controller: @commentable_type.downcase.pluralize, action: "show", locale: I18n.locale,
                      id: @commentable_id, status: :unprocessable_entity
        }
      end
    end
  end

  # GET /comments/1/edit only for admin or own user
  def edit
    return unless access?(:update, @comment)
  end

  # PATCH /comments/1
  def update
    return unless access?(:update, @comment)

    respond_to do |format|
      if @comment.update(comment_params)
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment", partial: "comments/comments_table") }
        format.html {
          redirect_to controller: @commentable_type.downcase.pluralize, action: "show", locale: I18n.locale,
                      id: @commentable_id, notice: "comment was successfully updated."
        }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  def destroy
    return unless access?(:destroy, @comment)

    respond_to do |format|
      if @comment.destroy
        @comments.reload
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment", partial: "comments/comments_table") }
        format.html {
          redirect_to controller: @commentable_type.downcase.pluralize,
                      action: "show",
                      locale: I18n.locale,
                      id: @commentable_id,
                      notice: t("comments.deleted", comment: truncate(@comment.comment, length: 20))
        }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # list comments created by a user ID
  # e.g. GET /quotations/list_by_user/1
  #      GET /quotations/list_by_user/1?page=42
  # it is free to be called w/o login, but actual it is only linked from admin view
  def list_by_user
    user_id = my_sql_sanitize(params[:user])

    unless User.exists?(id: user_id)
      flash[:error] = t("g.missing_user", user: params[:user])
      return redirect_to root_url
    end

    @comments = Comment.where(user_id: user_id).order(created_at: :desc)

    @comments = @comments.paginate(page: params[:page], per_page: PER_PAGE)
    # check pagination second time with number of pages
    bad_pagination?(@comments.total_pages)
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
    @commentable_type = @comment.commentable_type
    @commentable_id = @comment.commentable_id
    @comments = Comment.where(commentable_type: @comment.commentable_type, commentable_id: @comment.commentable_id)
    logger.debug { "set_comment: id=#{params[:id]}, @comment=#{@comment.inspect}, @comments.count=#{@comments.count}" }
  rescue
    flash[:error] = t("comments.id_does_not_exist", id: params[:id])
    render "static_pages/not_found", status: :not_found
  end

  # Only allow a list of trusted parameters through.
  def comment_params
    params.require(:comment).permit(:comment, :locale, :commentable_type, :commentable_id)
  end
end
