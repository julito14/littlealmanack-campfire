# The welcome note a new member sees on their first visit tells us it was shown, so it isn't
# shown again, on this device or any other.
class WelcomeNotesController < ApplicationController
  def create
    Current.user.update!(welcomed_at: Time.current) unless Current.user.welcomed_at
    head :no_content
  end
end
