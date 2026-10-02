class Accounts::OpenSignupsController < ApplicationController
  before_action :ensure_can_administer

  def create
    Current.account.update!(open_signup: true)
    redirect_to account_invitations_url
  end

  # A new public link; the old one stops working.
  def update
    Current.account.reset_join_code
    redirect_to account_invitations_url
  end

  def destroy
    Current.account.update!(open_signup: false)
    redirect_to account_invitations_url
  end
end
