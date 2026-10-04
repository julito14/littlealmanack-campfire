class Accounts::SignupRedirectsController < ApplicationController
  before_action :ensure_can_administer

  def update
    unless Current.account.update(closed_signup_url: params.dig(:account, :closed_signup_url))
      flash[:alert] = "That doesn't look like a web address. Try something like yoursite.com/join."
    end

    redirect_to account_invitations_url
  end
end
