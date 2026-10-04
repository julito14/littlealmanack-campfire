module Message::Broadcasts
  # Replies go out on the room's own stream, aimed at the thread's list, so they appear for
  # anyone with the thread open and are ignored by the room's timeline.
  def broadcast_create
    if reply?
      broadcast_append_to room, :messages, target: [ parent_message, :replies ]
      parent_message.broadcast_thread_summary
    else
      broadcast_append_to room, :messages, target: [ room, :messages ]
    end

    broadcast_unread_room
  end

  def broadcast_remove
    broadcast_remove_to room, :messages
    parent_message.reload.broadcast_thread_summary if reply?
  end

  # The "3 replies" line under the message in the room, and the count heading the thread.
  def broadcast_thread_summary
    broadcast_replace_to room, :messages, target: [ self, :thread_summary ],
      partial: "messages/thread_summary", locals: { message: self }, attributes: { maintain_scroll: true }
    broadcast_replace_to room, :messages, target: [ self, :replies_count ],
      partial: "messages/threads/replies_count", locals: { parent: self }
  end

  private
    # Fanned out to the room's members rather than published on one global stream, so
    # that the timing of activity in a room only reaches people who are in it.
    def broadcast_unread_room
      unread_user_ids.each do |user_id|
        ActionCable.server.broadcast UnreadRoomsChannel.stream_name_for(user_id), { roomId: room.id }
      end
    end

    def unread_user_ids
      if reply?
        room.memberships.where(user_id: thread_audience_ids).pluck(:user_id)
      else
        room.memberships.pluck(:user_id)
      end
    end
end
