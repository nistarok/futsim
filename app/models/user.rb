class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :provider, presence: true, if: :persisted?
  validates :uid, presence: true, if: :persisted?
  validates :name, presence: true, if: :persisted?
  
  # Validations for invitation tokens
  validates :invitation_token, uniqueness: { allow_nil: true }
  
  # Scopes
  scope :invited, -> { where.not(invitation_token: nil) }
  scope :active, -> { where(invitation_token: nil) }
  
  # Callbacks
  before_create :generate_invitation_token, if: :new_record?
  
  # Class methods
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at) if auth.credentials.expires_at
    end
  end
  
  def self.invite!(email)
    user = find_or_initialize_by(email: email)
    if user.new_record?
      user.generate_invitation_token
      user.invitation_created_at = Time.current
      user.save!
    elsif user.invited?
      # User already exists and is invited, just return the user
      user
    else
      # User exists but is not invited, add invitation
      user.generate_invitation_token
      user.invitation_created_at = Time.current
      user.save!
    end
    user
  end
  
  # Instance methods
  def invited?
    invitation_token.present?
  end

  def active?
    !invited?
  end
  
  def invitation_expired?
    invitation_created_at.present? && invitation_created_at < 24.hours.ago
  end
  
  def accept_invitation!
    update(invitation_token: nil, invitation_created_at: nil)
  end
  
  def generate_invitation_token
    self.invitation_token = SecureRandom.urlsafe_base64
    self.invitation_created_at = Time.current
  end
  
  def avatar_url
    # Return avatar URL if available from OAuth provider
    # For Google, this would typically be in auth.info.image
    nil
  end
end
