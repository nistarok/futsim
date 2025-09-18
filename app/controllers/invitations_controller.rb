class InvitationsController < ApplicationController
  before_action :authenticate_admin!

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
end
