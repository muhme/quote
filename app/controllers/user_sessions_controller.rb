class UserSessionsController < ApplicationController

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(user_session_params)
    if @user_session.save
      flash[:notice] = "Hallo #{current_user.login}, schön dass Du da bist."
      redirect_to root_url
    else
      flash[:error] = "Die Anmeldung war nicht erfolgreich!"
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    redirect_to new_user_session_url
  end

  private

    def user_session_params
      params.require(:user_session).permit(:login, :password)
    end
end