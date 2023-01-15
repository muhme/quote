class UserSessionsController < ApplicationController

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(user_session_params.to_h)
    if @user_session.save
      flash[:notice] = "Hallo #{current_user.login}, schön dass Du da bist."
      redirect_to root_url
    else
      flash[:error] = "Die Anmeldung war nicht erfolgreich!"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    current_user_session.destroy unless current_user_session.nil?
    redirect_to new_user_session_url
  end

  private

    def user_session_params
      params.require(:user_session).permit(:login, :password, :remember_me)
    end
end