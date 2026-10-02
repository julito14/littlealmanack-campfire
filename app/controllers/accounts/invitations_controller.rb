class Accounts::InvitationsController < ApplicationController
  before_action :ensure_can_administer

  def index
    @invitation = Invitation.new
    set_invitations
  end

  def create
    @invitation = Invitation.new(invitation_params)

    if @invitation.save
      redirect_to account_invitations_url
    else
      set_invitations
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    Invitation.pending.find(params[:id]).destroy
    redirect_to account_invitations_url
  end

  private
    def set_invitations
      @pending_invitations = Invitation.pending.ordered
      @accepted_invitations = Invitation.accepted.includes(:user).ordered
      @open_signup_count = User.active.where(joined_via: "open_link").count
    end

    def invitation_params
      params.require(:invitation).permit(:email_address)
    end
end
