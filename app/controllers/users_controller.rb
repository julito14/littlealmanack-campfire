class UsersController < ApplicationController
  require_unauthenticated_access only: %i[ new create ]

  before_action :set_user, only: :show
  before_action :set_invitation, only: %i[ new create ]

  def new
    @user = User.new(email_address: @invitation.email_address)
  end

  def create
    @user = @invitation.accept(user_params)
    start_new_session_for @user
    redirect_to root_url
  rescue ActiveRecord::RecordNotUnique
    redirect_to new_session_url(email_address: @invitation.email_address)
  end

  def show
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def set_invitation
      @invitation = Invitation.pending.find_by(token: params[:token])
      head :not_found unless @invitation
    end

    def user_params
      params.require(:user).permit(:name, :avatar, :password)
    end
end
