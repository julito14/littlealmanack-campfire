class Room::MessagePusher
  attr_reader :room, :message

  def initialize(room:, message:)
    @room, @message = room, message
  end

  def push
    build_payload.tap do |payload|
      if message.reply?
        push_to_thread_audience(payload)
      else
        push_to_users_involved_in_everything(payload)
        push_to_users_involved_in_mentions(payload)
      end
    end
  end

  private
    def build_payload
      if room.direct?
        build_direct_payload
      elsif message.reply?
        build_thread_payload
      else
        build_shared_payload
      end
    end

    def build_thread_payload
      {
        title: "Thread in #{room.name}",
        body: "#{message.creator.name}: #{message.plain_text_body}",
        path: Rails.application.routes.url_helpers.room_message_thread_path(room, message.parent_message)
      }
    end

    # Unlike the room's own messages, a reply reaches only the people in its thread (and
    # anyone it mentions), whether the room is set to everything or to mentions. Muting the
    # room still silences it.
    def push_to_thread_audience(payload)
      enqueue_payload_for_delivery payload,
        relevant_subscriptions.merge(Membership.where(involvement: %w[ mentions everything ])).where(user_id: message.thread_audience_ids)
    end

    def build_direct_payload
      {
        title: message.creator.name,
        body: message.plain_text_body,
        path: Rails.application.routes.url_helpers.room_path(room)
      }
    end

    def build_shared_payload
      {
        title: room.name,
        body: "#{message.creator.name}: #{message.plain_text_body}",
        path: Rails.application.routes.url_helpers.room_path(room)
      }
    end

    def push_to_users_involved_in_everything(payload)
      enqueue_payload_for_delivery payload, push_subscriptions_for_users_involved_in_everything
    end

    def push_to_users_involved_in_mentions(payload)
      enqueue_payload_for_delivery payload, push_subscriptions_for_mentionable_users(message.mentionees)
    end

    def push_subscriptions_for_users_involved_in_everything
      relevant_subscriptions.merge(Membership.involved_in_everything)
    end

    def push_subscriptions_for_mentionable_users(mentionees)
      relevant_subscriptions.merge(Membership.involved_in_mentions).where(user_id: mentionees.ids)
    end

    def relevant_subscriptions
      Push::Subscription
        .joins(user: :memberships)
        .merge(Membership.visible.disconnected.where(room: room).where.not(user: message.creator))
    end

    def enqueue_payload_for_delivery(payload, subscriptions)
      Rails.configuration.x.web_push_pool.queue(payload, subscriptions)
    end
end
