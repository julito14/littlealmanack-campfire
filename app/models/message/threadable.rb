# Replies to a message form its thread. They live in the message's room, so anyone who can
# see the room can read and join the thread, but they stay out of the room's main timeline.
# One level only: a reply can't start a thread of its own, and private pings have none.
module Message::Threadable
  extend ActiveSupport::Concern

  REPLIERS_SHOWN = 3

  included do
    belongs_to :parent_message, class_name: "Message", optional: true, counter_cache: :replies_count, touch: true
    has_many :replies, -> { ordered }, class_name: "Message", foreign_key: :parent_message_id,
      inverse_of: :parent_message, dependent: :destroy

    scope :top_level, -> { where(parent_message_id: nil) }

    validate :parent_message_takes_replies, on: :create, if: :parent_message
  end

  def reply?
    parent_message_id.present?
  end

  def threadable?
    !reply? && !room.direct?
  end

  def last_reply_at
    replies.maximum(:created_at)
  end

  # The latest people to reply, most recent first, for the avatars under the message.
  def recent_repliers
    ids = replies.reorder(created_at: :desc).pluck(:creator_id).uniq.first(REPLIERS_SHOWN)
    User.where(id: ids).index_by(&:id).values_at(*ids).compact
  end

  # Who hears about a reply: whoever started the conversation, everyone who has replied so
  # far, and anyone the reply mentions. The rest of the room just sees the count go up.
  def thread_audience_ids
    if reply?
      [ parent_message.creator_id, *parent_message.replies.pluck(:creator_id), *mentionees.ids ].uniq - [ creator_id ]
    else
      []
    end
  end

  private
    def parent_message_takes_replies
      unless parent_message.threadable? && parent_message.room_id == room_id
        errors.add :parent_message, "can't be replied to in a thread"
      end
    end
end
