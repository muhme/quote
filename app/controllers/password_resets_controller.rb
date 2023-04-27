# based on https://github.com/rejeep/authlogic-password-reset-tutorial
class PasswordResetsController < ApplicationController
  before_action :logout, :only => [:new]
  before_action :load_user_using_perishable_token, :only => [:edit, :update]

  # render view new
  def new
  end

  # after view new
  def create
    @user = User.find_by_email(params[:email])
    if @user
      @user.deliver_password_reset_instructions!
      redirect_to root_path, notice: t(".email_sent", email: @user.email)
    else
      flash.now[:error] = t(".email_not_found", email: params[:email])
      render :action => :new, status: :unprocessable_entity
    end
  end

  # render view edit
  def edit
  end

  # after view edit
  def update
    @user.password = params[:password]
    @user.password_confirmation = params[:password_confirmation]

    # save new password and sign in the user
    if @user.save
      redirect_to root_path, notice: t(".updated", login: @user.login)
    else
      render :action => :edit
    end
  end

  private

  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])

    if @user.nil? or (@user.login != params[:login])
      flash[:error] = t("password_resets.not_allowed", login: params[:login])
      redirect_to root_url
    end
  end

  def logout
    if current_user_session
      current_user_session.destroy
    end
  end
end
