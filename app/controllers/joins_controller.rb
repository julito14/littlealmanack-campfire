# The permanent address to share (/join): it follows whatever sign-up is current, so links
# in old articles and emails keep working when the public link changes or sign-up closes.
class JoinsController < ApplicationController
  allow_unauthenticated_access

  def show
    if Current.account.open_signup?
      redirect_to join_url(Current.account.join_code)
    elsif Current.account.closed_signup_url.present?
      redirect_to Current.account.closed_signup_url, allow_other_host: true
    end
  end
end
