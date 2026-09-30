# A one-time invite for one email address. Replaces the account-wide join code, so only
# administrators can bring people in, and a link stops working once it has been used.
class Invitation < ApplicationRecord
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  belongs_to :user, optional: true

  has_secure_token

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  scope :pending,  -> { where(accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :ordered,  -> { order(created_at: :desc) }

  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :email_address_not_already_invited, :email_address_not_already_a_member, on: :create

  # The email always comes from the invitation, never from the form, so a forwarded link
  # can't be used to sign up under someone else's address.
  def accept(user_attributes)
    transaction do
      User.create!(user_attributes.merge(email_address: email_address)).tap do |user|
        update! user: user, accepted_at: Time.current
      end
    end
  end

  def accepted?
    accepted_at.present?
  end

  private
    def email_address_not_already_invited
      errors.add :email_address, "already has a pending invitation" if Invitation.pending.exists?(email_address: email_address)
    end

    def email_address_not_already_a_member
      errors.add :email_address, "already belongs to a member" if User.active.exists?(email_address: email_address)
    end
end
