class ApplicationController < ActionController::Base
  before_action :set_current_user

  private

  def set_current_user
    @current_user = User.find(session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    @current_user.present?
  end

  def current_user
    @current_user
  end

  def authenticate_user!
    redirect_to root_path, alert: 'Please sign in to access this page.' unless user_signed_in?
  end
end
