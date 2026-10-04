# Sent by an open thread page as replies arrive, so they don't show as unread in the strip.
class Messages::Threads::ReadingsController < ApplicationController
  include RoomScoped

  def create
    parent_message = @room.messages.find(params[:message_id])
    Current.user.thread_participations.find_by(message: parent_message)&.read

    head :no_content
  end
end
