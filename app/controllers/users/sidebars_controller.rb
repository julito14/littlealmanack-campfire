class Users::SidebarsController < ApplicationController
  THREADS_LISTED = 50

  def show
    all_memberships     = Current.user.memberships.visible.with_ordered_room
    @direct_memberships = extract_direct_memberships(all_memberships)
    @other_memberships  = all_memberships.without(@direct_memberships)

    @threads = find_threads
    @unread_thread_ids = Current.user.thread_participations.unread.where(message_id: @threads.map(&:id)).pluck(:message_id).to_set
    @members = User.active.without_bots.ordered
  end

  private
    def extract_direct_memberships(all_memberships)
      all_memberships.select { |m| m.room.direct? }.sort_by { |m| m.room.updated_at }.reverse
    end

    # Every thread in the member's rooms that had a reply in the last 30 days, newest first.
    def find_threads
      Message.where(room_id: Current.user.memberships.visible.select(:room_id))
        .listed_threads.limit(THREADS_LISTED).preload(:room, :creator).to_a
    end
end
