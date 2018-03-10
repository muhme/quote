class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :destroy]

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  def create
    @user = User.new(user_params)
    @user.active = @user.approved = @user.confirmed = true # NICE email handling

    if @user.save
      redirect_to root_url, notice: "Der Eintrag für den Benutzer \"#{@user.login}\” wurde angelegt."
    else
      format.html { render :new }
    end
  end
  
  def edit
    @user = current_user
  end

  # PATCH/PUT /users/1
  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'User was successfully updated.'
    else
      format.html { render :edit }
    end
  end

  # DELETE /users/1 not allowed
  # def destroy
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:login, :email, :password, :password_confirmation)
    end
end
