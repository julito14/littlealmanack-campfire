# Replies to a message form its thread. They live in the message's room, so anyone who can
# see the room can read and join the thread, but they stay out of the room's main timeline.
# One level only: a reply can't start a thread of its own, and private DMs have none.
module Message::Threadable
  extend ActiveSupport::Concern

  REPLIERS_SHOWN = 3

  # A thread stays in the Threads list this long after its latest reply; the next one brings it back.
  LISTED_FOR = 30.days

  included do
    belongs_to :parent_message, class_name: "Message", optional: true, counter_cache: :replies_count, touch: true
    has_many :replies, -> { ordered }, class_name: "Message", foreign_key: :parent_message_id,
      inverse_of: :parent_message, dependent: :destroy
    has_many :thread_participations, dependent: :delete_all

    scope :top_level, -> { where(parent_message_id: nil) }
    scope :listed_threads, -> { where(last_reply_at: LISTED_FOR.ago..).order(last_reply_at: :desc) }

    validate :parent_message_takes_replies, on: :create, if: :parent_message

    after_create :stamp_parent_with_last_reply, if: :reply?
    after_create_commit :bring_audience_into_thread, if: :reply?
    after_destroy :restamp_parent_with_last_reply, if: :reply?
  end

  def reply?
    parent_message_id.present?
  end

  def threadable?
    !reply? && !room.direct?
  end

  # The latest people to reply, most recent first, for the avatars under the message.
  def recent_repliers(limit: REPLIERS_SHOWN)
    ids = replies.reorder(created_at: :desc).pluck(:creator_id).uniq.first(limit)
    User.where(id: ids).index_by(&:id).values_at(*ids).compact
  end

  # Who hears about a reply: whoever started the conversation, everyone who has replied or been
  # mentioned in it so far, and anyone this reply mentions. The rest of the room just sees the
  # count go up.
  def thread_audience_ids
    if reply?
      [ parent_message.creator_id, *parent_message.replies.pluck(:creator_id),
        *parent_message.thread_participations.pluck(:user_id), *mentionees.ids ].uniq - [ creator_id ]
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

    def stamp_parent_with_last_reply
      parent_message.update_column :last_reply_at, created_at
    end

    def restamp_parent_with_last_reply
      parent_message.update_column :last_reply_at, parent_message.replies.maximum(:created_at)
    end

    # The replier joins (caught up); everyone else the reply concerns joins too, with it unread.
    def bring_audience_into_thread
      audience_ids = thread_audience_ids

      ThreadParticipation.insert_all [ creator_id, *audience_ids ].map { |user_id| { message_id: parent_message_id, user_id: user_id } },
        unique_by: %i[ message_id user_id ]
      parent_message.thread_participations.where(user_id: audience_ids).update_all(unread_at: created_at, updated_at: Time.current)
    end
end
