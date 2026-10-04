module Message::Broadcasts
  # Replies go out on the room's own stream, aimed at the thread's list, so they appear for
  # anyone with the thread open and are ignored by the room's timeline.
  def broadcast_create
    if reply?
      broadcast_append_to room, :messages, target: [ parent_message, :replies ]
      parent_message.broadcast_thread_summary
      parent_message.broadcast_thread_rows
    else
      broadcast_append_to room, :messages, target: [ room, :messages ]
      broadcast_new_direct_room if room.direct? && room.messages.one?
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

  # Moves the thread to the top of every room member's Threads list: bold for the people in it
  # who haven't read the latest replies, plain for everyone else. Rendered twice, not per member.
  def broadcast_thread_rows
    unread_user_ids = thread_participations.unread.pluck(:user_id).to_set
    rows = { true => render_thread_row(unread: true), false => render_thread_row(unread: false) }

    User.where(id: room.memberships.visible.select(:user_id)).find_each do |user|
      broadcast_thread_row_to user, html: rows[unread_user_ids.include?(user.id)]
    end
  end

  def broadcast_thread_row_to(user, unread: false, html: render_thread_row(unread: unread))
    Turbo::StreamsChannel.broadcast_append_to user, :rooms, target: "thread_rows", html: html
  end

  private
    # A DM shows up in its members' lists once something has been said in it.
    def broadcast_new_direct_room
      room.memberships.includes(:user).each do |membership|
        membership.broadcast_prepend_to membership.user, :rooms, target: :direct_rooms, partial: "users/sidebars/rooms/direct"
      end
    end

    def render_thread_row(unread:)
      ApplicationController.render partial: "users/sidebars/thread_row", locals: { thread: self, unread: unread }
    end

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
