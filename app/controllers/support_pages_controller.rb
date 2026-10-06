# "Support & tips", at the bottom of Rooms: how to reach the club and how to get the most out of
# it. A page to read rather than a chat: everyone can read it, administrators edit it.
class SupportPagesController < ApplicationController
  before_action :ensure_administrator, only: %i[ edit update ]

  def show
  end

  def edit
  end

  def update
    Current.account.update!(params.require(:account).permit(:support_text))
    redirect_to support_page_url, notice: "Saved"
  end

  private
    def ensure_administrator
      head :forbidden unless Current.user.administrator?
    end
end
