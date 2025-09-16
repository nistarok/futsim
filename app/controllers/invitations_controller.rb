class InvitationsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @invited_users = User.invited.order(:created_at)
  end
  
  def create
    email = params[:email]
    if email.present?
      user = User.invite!(email)
      # In a real application, you would send an email here
      redirect_to invitations_path, notice: "Invitation sent to #{email}"
    else
      redirect_to invitations_path, alert: 'Please provide an email address'
    end
  end
  
  def destroy
    user = User.find(params[:id])
    user.destroy
    redirect_to invitations_path, notice: 'Invitation revoked'
  end
  
  private

  def require_admin
    # Future: Add admin role check when admin system is implemented
    # redirect_to root_path, alert: 'Access denied' unless current_user&.admin?
  end
end
