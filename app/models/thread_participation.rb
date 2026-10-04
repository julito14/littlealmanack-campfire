# A member's place in a thread: whoever started it, replied in it, or was mentioned in a reply.
# It's what makes the thread bold in their Threads list when there are replies they haven't seen.
class ThreadParticipation < ApplicationRecord
  belongs_to :message # the thread's opening message
  belongs_to :user

  scope :unread, -> { where.not(unread_at: nil) }

  def unread?
    unread_at.present?
  end

  def read
    if unread?
      update!(unread_at: nil)
      message.broadcast_thread_row_to user, unread: false
    end
  end
end
