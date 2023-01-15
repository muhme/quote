class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :destroy]

  # GET /users/new
  def new
    @user = User.new
  end

  # POST /users
  def create
    @user = User.new(user_params)
    @user.active = @user.approved = @user.confirmed = true # NICE email handling

    if @user.save
      redirect_to root_url, notice: "Der Eintrag für den Benutzer \"#{@user.login}\” wurde angelegt."
    else
      render :new, status: :unprocessable_entity
    end

  end

  # GET /users/1/edit
  def edit
    unless current_user
      flash[:error] = "Nicht angemeldet!"
      redirect_to root_url
    end
    @user = current_user
  end

  # PATCH/PUT /users/1
  def update
    unless current_user
      flash[:error] = "Nicht angemeldet!"
      redirect_to root_url
      return
    end

    if @user.update(user_params)
      redirect_to root_url, notice: 'Benutzereintrag wurde geändert.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /users/1 not allowed
  # def destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = current_user  # only allow current user
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:login, :email, :password, :password_confirmation)
    end
end
