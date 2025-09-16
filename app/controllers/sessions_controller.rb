class SessionsController < ApplicationController
  def create
    auth = request.env['omniauth.auth']

    # First check if we have an invited user by email
    user = User.find_by(email: auth.info.email)

    if user&.invited? && !user.invitation_expired?
      # Update user with OAuth data and accept invitation
      user.update!(
        provider: auth.provider,
        uid: auth.uid,
        name: auth.info.name,
        oauth_token: auth.credentials.token,
        oauth_expires_at: auth.credentials.expires_at ? Time.at(auth.credentials.expires_at) : nil
      )
      user.accept_invitation!
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Successfully signed in!'
    elsif user&.invited? && user.invitation_expired?
      redirect_to root_path, alert: 'Your invitation has expired. Please contact an administrator.'
    elsif user && !user.invited?
      # User exists and is already active
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Welcome back!'
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
