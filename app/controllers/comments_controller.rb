class CommentsController < ApplicationController
  before_action :set_comment, only: [:edit, :update, :destroy]

  # GET /comments only for admins
  def index
    if !current_user or current_user.admin == false
      flash[:error] = t("g.no_admin")
      render "static_pages/forbidden", status: :forbidden
      return false
    end
    @comments = Comment.paginate_by_sql "select * from comments order by updated_at desc", :page => params[:page], :per_page => 10
    # check pagination second time with number of pages
    bad_pagination?(@comments.total_pages)
  end

  # POST /comments/new
  def create
    return unless logged_in? t("categories.login_missing")
    @comment = Comment.new(comment_params)
    @comment.user_id = current_user.id
    @commentable_type = @comment.commentable_type
    @commentable_id = @comment.commentable_id

    respond_to do |format|
      if @comment.save
        format.turbo_stream
        format.html { redirect_to controller: @commentable_type.downcase.pluralize, action: 'show', locale: I18n.locale, id:  @commentable_id }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("#{helpers.dom_id(@comment)}_form", partial: "new") }
        format.html {
          if @comment.errors.any?
            error = t("g.error", count: @comment.errors.count)
            @comment.errors.each do |message|
              error << ". #{message.full_message}!"
            end
            flash[:error] = error
          end
          logger.error "comment.save FAILED with #{error}"
          redirect_to controller: @commentable_type.downcase.pluralize, action: 'show', locale: I18n.locale, id: @commentable_id, status: :unprocessable_entity }
      end
    end
  end

  # GET /comments/1/edit only for admin or own user
  def edit
    return unless access?(@comment, :update)
  end

  # PATCH /comments/1
  def update
    return unless access?(@comment, :update)

    @commentable_type = @comment.commentable_type
    @commentable_id = @comment.commentable_id

    respond_to do |format|
      if @comment.update(comment_params)
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_#{@comment.id}_container", partial: "comments/comment", locals: { comment: @comment }) }
        format.html { redirect_to controller: @commentable_type.downcase.pluralize, action: 'show', locale: I18n.locale, id:  @commentable_id, notice: "comment was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  def destroy
    return unless access?(@comment, :destroy)
    @commentable_type = @comment.commentable_type
    @commentable_id = @comment.commentable_id

    respond_to do |format|
      if @comment.destroy
        format.turbo_stream { render turbo_stream: turbo_stream.remove_all(".#{helpers.dom_id(@comment)}_tr") }
        # format.html { redirect_to categories_url, notice: t(".deleted", comment: truncate(@comment.comment, length: 20)) }
        format.html { redirect_to controller: @commentable_type.downcase.pluralize, action: 'show', locale: I18n.locale, id:  @commentable_id, notice: t(".deleted", comment: truncate(@comment.comment, length: 20)) }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  rescue
    flash[:error] = t("comments.id_does_not_exist", id: params[:id])
    render "static_pages/not_found", status: :not_found
  end

  # Only allow a list of trusted parameters through.
  def comment_params
    params.require(:comment).permit(:comment, :locale, :commentable_type, :commentable_id)
  end
end
