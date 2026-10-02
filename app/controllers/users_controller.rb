class UsersController < ApplicationController
  require_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  before_action :set_user, only: :show
  before_action :set_invitation, only: %i[ new create ]

  def new
    @user = User.new(email_address: @invitation&.email_address)
  end

  def create
    if @invitation
      @user = @invitation.accept(user_params)
    elsif open_signup_email_address.match?(URI::MailTo::EMAIL_REGEXP)
      @user = create_through_open_signup
    else
      return head :unprocessable_entity
    end

    start_new_session_for @user
    redirect_to root_url
  rescue ActiveRecord::RecordInvalid => invalid
    @user = invalid.record
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotUnique
    redirect_to new_session_url(email_address: @invitation&.email_address || open_signup_email_address)
  end

  def show
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    # A personal invitation, or the public link while open sign-up is on.
    def set_invitation
      @invitation = Invitation.pending.find_by(token: params[:token])
      head :not_found unless @invitation || Current.account.open_signup_link?(params[:token])
    end

    def create_through_open_signup
      User.create!(user_params.merge(email_address: open_signup_email_address, joined_via: "open_link")).tap do |user|
        Invitation.pending.find_by(email_address: user.email_address)&.update!(user: user, accepted_at: Time.current)
      end
    end

    def open_signup_email_address
      params.dig(:user, :email_address).to_s.strip.downcase
    end

    def user_params
      params.require(:user).permit(:name, :avatar, :password, :bio, :location, :books)
    end
end
