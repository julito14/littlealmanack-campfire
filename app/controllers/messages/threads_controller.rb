class Messages::ThreadsController < ApplicationController
  include ActiveStorage::SetCurrent, RoomScoped

  # Long threads open on their latest replies. Older ones aren't paged in: the thread's
  # opening message sits above them, and that's where scrolling up stops.
  REPLIES_SHOWN = 300

  before_action :set_parent_message

  def show
    @replies = @parent_message.replies.with_creator.with_attachment_details.with_boosts.last(REPLIES_SHOWN)
    Current.user.thread_participations.find_by(message: @parent_message)&.read unless prefetch?
  end

  private
    # Turbo fetches pages ahead on hover; that isn't reading the thread. The page itself
    # confirms the read once it's on screen (thread_reading_controller.js).
    def prefetch?
      request.headers["X-Sec-Purpose"] == "prefetch"
    end

    def set_parent_message
      message = @room.messages.find(params[:message_id])
      @parent_message = message.parent_message || message

      redirect_to room_at_message_url(@room, @parent_message) unless @parent_message.threadable?
    end
end
