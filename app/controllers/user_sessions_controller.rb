class UserSessionsController < ApplicationController
  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(user_session_params.to_h)
    if @user_session.save
      @current_user = @user_session.user
      flash[:notice] = t(".hello", user: current_user&.login)
      redirect_to root_path(locale: I18n.locale)
    else
      flash[:error] = t(".login_failed")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    current_user_session.destroy unless current_user_session.nil?
    redirect_to new_user_session_url
  end

  private

  def user_session_params
    params.require(:user_session).permit(:login, :password)
  end
end
