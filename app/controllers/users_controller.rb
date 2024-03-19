# app/controllers/user_controller.rb
#
# create and update a user entry with login-name, e-mail, password and avatar image
# - works together with Stimulus avatar controller
# - `@avatar_image` is saved in the hidden field `user_avatar_image` to have it as `params[:user][:avatar_image]`
#   for saving when updating
# - `src` of the three avatar images `avatar_big`, `avatar` and `avatar_small` is either `images/*/{user.id}.png` or,
#   if the avater image has been changed, Base64 encoded `data:image/png` with a size of about 5k
# - to avoid having the 5k Base64 encoded image four times in the HTML source, it is only copied into the hidden field
#   and then copied into the three images `src` with (immediately invoked function expression) JavaScript
# - an uploaded image file is temporarily saved as a session avatar image `images/*/{session.id}.png`
#   . the session avatar image implies an additional status that must be handled in addition to
#     `params[:user][:avatar_image]`
#   . if the session avatar image file is present in create() or update() it must be used and the file must be deleted
#   . if a new avatar is generated or copied from Gravatar a possible existing session avatar image file must be deleted
#   . etc. pp.
# - there is `@avatar_hint` for notices with green animation and `@avatar_error` for failures with red animation
# - only for new()
#   . focusout from login field creates an image from login name
#   . focusout from email field checks for Gravatar and copies a found Gravatar as users avatar image
#
class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update]

  # GET /users/new
  def new
    @user = User.new
    # is there are an uploaded image from previous new() in this session?
    session_avatar_image = AvatarService::session_avatar_image(session.id)
    if session_avatar_image
      # use uploaded session image
      @avatar_image = session_avatar_image
    else
      # extract avatar_image from params and then remove it from the user_params hash
      @avatar_image = "#{AVATARS_URL}/0.png" # start with default, which is a gray '?' avatar image
    end
  end

  # POST /users
  def create
    session_avatar_image = AvatarService::session_avatar_image(session.id)
    if session_avatar_image
      # use uploaded session image
      avatar_image = session_avatar_image
      # update user without avatar_image parameter (session avatar has 1st prio)
      params[:user].delete(:avatar_image)
    else
      # extract avatar_image from params and then remove it from the user_params hash
      avatar_image = params[:user].delete(:avatar_image)
    end

    @user = User.new(user_params)
    @user.active = @user.approved = @user.confirmed = true # NICE email handling

    if @user.save
      AvatarService::store_avatar(@user.id, avatar_image) if avatar_image.present?
      AvatarService::delete_session_avatar_image_file(session.id) # if uploaded file exist delete now
      redirect_to root_url, notice: t(".created", user: @user.login)
    else
      # get avatar image from saved content of the hidden form field
      @avatar_image = avatar_image
      logger.debug { "create: save faild, reset @avatar_image=\"#{avatar_image}\"" }
      render :new, status: :unprocessable_entity
    end
  end

  # GET /users/1/edit
  def edit
    unless current_user
      flash[:error] = t("users.not_logged_in")
      redirect_to root_url
    end
    @user = current_user
    session_avatar_image = AvatarService::session_avatar_image(session.id)
    if session_avatar_image
      @avatar_image = session_avatar_image
    else
      @avatar_image = "#{AVATARS_URL}/#{current_user&.id || 0}.png"
    end
  end

  # PATCH/PUT /users/1
  def update
    unless current_user
      flash[:error] = t("users.not_logged_in")
      redirect_to root_url
      return
    end

    session_avatar_image = AvatarService::session_avatar_image(session.id)
    if session_avatar_image
      # use uploaded session image
      avatar_image = session_avatar_image
      # update user without avatar_image parameter (session avatar has 1st prio)
      params[:user].delete(:avatar_image)
    else
      # extract avatar_image from params and then remove it from the user_params hash
      avatar_image = params[:user].delete(:avatar_image)
    end

    if @user.update(user_params)
      AvatarService::store_avatar(@user.id, avatar_image) if avatar_image.present?
      AvatarService::delete_session_avatar_image_file(session.id) # if uploaded file exist delete now
      respond_to do |format|
        format.html { redirect_to root_url, notice: t(".updated", user: @user.login) }
        # do aditional for Safari browser to update avatar image in menu
        format.js { render js: "Turbo.visit(window.location.href, {action: 'replace'});" }
      end
    else
      # get avatar image from saved content of the hidden form field
      @avatar_image = avatar_image
      render :edit, status: :unprocessable_entity
    end
  end

  # GET /users
  def index
    if !current_user or current_user.admin == false
      flash[:error] = t("g.no_admin")
      render "static_pages/forbidden", status: :forbidden
      return false
    end

    @users = User.with_quotations_or_comments.order(:login).paginate(page: params[:page], per_page: 10)
    # check pagination second time with number of pages
    bad_pagination?(@users.total_pages)
  end

  # GET users/show_avatar, only for turbo stream
  #
  # update the three avatar images with Turbo
  # called from Hotwire Stimulus after login name field focus out or email field focus out
  #
  # in case of any error return silently with HTTP 200 response with no content
  #
  def show_avatar
    if params[:login].present?
      if img = AvatarService::generate_base64_avatar_from_login(params[:login])
        logger.debug { "show_avatar from login=\"#{params[:login]}\"" }
        @avatar_image = img
        @avatar_hint = t(".generated_automatically")
        respond_to do |format|
          format.turbo_stream
        end
      else
        # HTTP 200 response with no content – silent failure, no image created
        head :ok
      end
    elsif params[:email].present?
      logger.debug { "show_avatar from email=\"#{params[:email]}\"" }
      if img = AvatarService::generate_base64_avatar_from_email(params[:email])
        @avatar_image = img
        @avatar_hint = t(".taken_from_gravatar")
        respond_to do |format|
          format.turbo_stream
        end
      else
        # HTTP 200 response with no content – silent failure, no Gravatar found for email
        head :ok
      end
    else
      # HTTP 200 response with no content – silent failure, should not happen
      flash[:error] = t("g.missing_params")
      return redirect_to root_url
    end
  end

  # POST users/upload_avatar
  #
  def upload_avatar
    if params[:image].present?
      image = params[:image] # Assuming the image is sent as a file
      logger.debug { "upload_avatar image=\"#{image.inspect}\"" }
      # process the image and convert it to base64
      base64_image = Base64.encode64(image.read) # .gsub("\n", '')
      logger.debug { "upload_avatar base64_image size=#{base64_image.size} \"#{base64_image[0...20]}...\"" }

      AvatarService::store_avatar(session.id, "data:image/png;base64," + base64_image) if base64_image.present?

      @avatar_image = "data:image/png;base64,#{base64_image}"
      # TODO: hint is already set from JavaScript, following is irrelevant ?as it is a POST request?
      @avatar_hint = ".taken_from_upload"
      respond_to do |format|
        format.html { redirect_to root_path, status: :see_other }
      end
    else
      logger.warn { "upload_avatar no params[:image]" }
      @avatar_error = ".image_upload_failed"
      # TODO: not working, ?as it is a POST request?
      respond_to do |format|
        format.turbo_stream { render 'show_avatar_message' }
      end
    end
  end

  # GET e.g. de/users/recreate_avatar?login=heiko, only for turbo stream
  #
  def recreate_avatar
    # if params[:login] is present use first two letters (in this case 'he'), if not use question mark ('?')
    if img = AvatarService::generate_base64_random_color_avatar(params[:login])
      logger.debug { "recreate_avatar from login=\"#{params[:login]}\"" }
      @avatar_image = img
      @avatar_hint = t(".created_with_random_color")
      AvatarService::delete_session_avatar_image_file(session.id) # if uploaded file exist delete now
      respond_to do |format|
        format.turbo_stream
      end
    else
      # HTTP 200 response with no content – silent failure, no image created
      head :ok
    end
  end

  # GET ja/users/take_gravatar, only for turbo stream
  def take_gravatar
    # either params[:email] is present or not
    if img = AvatarService::generate_base64_avatar_from_email(params[:email])
      logger.debug { "take_gravatar from email=\"#{params[:email]}\"" }
      @avatar_image = img
      @avatar_hint = t(".copied_from_gravatar")
      AvatarService::delete_session_avatar_image_file(session.id) # if uploaded file exist delete now
      respond_to do |format|
        format.turbo_stream
      end
    else
      @avatar_error = t(".not_found", email: params[:email])
      respond_to do |format|
        format.turbo_stream { render 'show_avatar_message' }
      end
    end
  end

  # DELETE /users/1 not allowed
  # def destroy
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = current_user # only allow current user
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(:login, :email, :password, :password_confirmation, :avatar_image)
  end
end
