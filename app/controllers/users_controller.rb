class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update]

  # GET /users/new
  def new
    @user = User.new
  end

  # POST /users
  def create
    @user = User.new(user_params)
    @user.active = @user.approved = @user.confirmed = true # NICE email handling

    if @user.save
      redirect_to root_url, notice: t(".created", user: @user.login)
    else
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
  end

  # PATCH/PUT /users/1
  def update
    unless current_user
      flash[:error] = t("users.not_logged_in")
      redirect_to root_url
      return
    end

    if @user.update(user_params)
      redirect_to root_url, notice: t(".updated", user: @user.login)
    else
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
    params.require(:user).permit(:login, :email, :password, :password_confirmation)
  end
end
