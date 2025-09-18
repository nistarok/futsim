class ApplicationController < ActionController::Base
  before_action :set_current_user
  before_action :set_locale

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

  def authenticate_admin!
    unless user_signed_in? && current_user.admin?
      # Don't reveal the existence of admin routes to regular users
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def set_locale
    I18n.locale = params[:locale] || session[:locale] || I18n.default_locale
    session[:locale] = I18n.locale
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
