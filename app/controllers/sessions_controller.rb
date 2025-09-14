class SessionsController < ApplicationController
  def create
    user = User.from_omniauth(request.env['omniauth.auth'])
    
    if user.invited? && !user.invitation_expired?
      user.accept_invitation!
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Successfully signed in!'
    elsif user.invited? && user.invitation_expired?
      redirect_to root_path, alert: 'Your invitation has expired. Please contact an administrator.'
    else
      redirect_to root_path, alert: 'You are not invited to access this application.'
    end
  end
  
  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'Successfully signed out!'
  end
  
  def failure
    redirect_to root_path, alert: "Authentication failed: #{params[:message]}"
  end
end
