class Users::SidebarsController < ApplicationController
  THREADS_LISTED = 50

  def show
    all_memberships     = Current.user.memberships.visible.with_ordered_room
    @direct_memberships = extract_direct_memberships(all_memberships)
    @local_memberships, @other_memberships = all_memberships.reject { |m| m.room.direct? }.partition { |m| m.room.local? }

    @threads = find_threads
    @unread_thread_ids = Current.user.thread_participations.unread.where(message_id: @threads.map(&:id)).pluck(:message_id).to_set
    @members = User.active.without_bots.ordered.includes(:city)
  end

  private
    # Only DMs where something has been said: tapping someone starts one, but it stays out of
    # both people's lists until the first message.
    def extract_direct_memberships(all_memberships)
      directs = all_memberships.select { |m| m.room.direct? }
      started = Message.where(room_id: directs.map(&:room_id)).distinct.pluck(:room_id).to_set

      directs.select { |m| started.include?(m.room_id) }.sort_by { |m| m.room.updated_at }.reverse
    end

    # Every thread in the member's rooms that had a reply in the last 30 days, newest first.
    def find_threads
      Message.where(room_id: Current.user.memberships.visible.select(:room_id))
        .listed_threads.limit(THREADS_LISTED).preload(:room, :creator).to_a
    end
end
