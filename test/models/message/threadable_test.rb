require "test_helper"

class Message::ThreadableTest < ActiveSupport::TestCase
  setup do
    @parent = messages(:first) # by Jason, in Designers
  end

  test "replies are counted and kept out of the room's timeline" do
    reply = reply_to @parent, by: :kevin, text: "Good point"

    assert_equal 1, @parent.reload.replies_count
    assert_equal [ reply ], @parent.replies
    assert reply.reply?
    assert_not_includes rooms(:designers).messages.top_level, reply
  end

  test "a reply can't start a thread of its own" do
    reply = reply_to @parent, by: :kevin, text: "Good point"

    assert_raises(ActiveRecord::RecordInvalid) { reply_to reply, by: :david, text: "Nested" }
    assert_not reply.threadable?
  end

  test "private pings have no threads" do
    ping = rooms(:david_and_kevin).messages.create!(creator: users(:david), body: "Psst")

    assert_not ping.threadable?
    assert_raises(ActiveRecord::RecordInvalid) { reply_to ping, by: :kevin, text: "Hi" }
  end

  test "a reply stays in its parent's room" do
    reply = rooms(:hq).messages.new(creator: users(:david), body: "Elsewhere", parent_message: @parent)

    assert_not reply.valid?
  end

  test "the audience is the original poster, earlier repliers and anyone mentioned, never the replier" do
    reply_to @parent, by: :kevin, text: "First"
    reply = reply_to @parent, by: :david, html: "Agreed, #{mention_attachment_for(:jz)}"

    assert_equal [ users(:jason), users(:kevin), users(:jz) ].map(&:id).sort, reply.thread_audience_ids.sort
  end

  test "a reply bolds the room only for its audience" do
    memberships = rooms(:designers).memberships.index_by { |m| m.user.name.downcase.to_sym }
    rooms(:designers).memberships.update_all(unread_at: nil)

    reply_to @parent, by: :kevin, text: "Only Jason hears about this"

    assert memberships[:jason].reload.unread?
    assert_not memberships[:jz].reload.unread?
    assert_not memberships[:david].reload.unread?
  end

  test "recent repliers come most recent first, once each" do
    reply_to @parent, by: :kevin, text: "One"
    reply_to @parent, by: :david, text: "Two"
    reply_to @parent, by: :kevin, text: "Three"

    assert_equal [ users(:kevin), users(:david) ], @parent.recent_repliers
  end

  test "deleting a message deletes its thread" do
    reply = reply_to @parent, by: :kevin, text: "Doomed"

    @parent.destroy

    assert_not Message.exists?(reply.id)
  end

  test "deleting a reply lowers the count" do
    reply = reply_to @parent, by: :kevin, text: "Oops"
    reply.destroy

    assert_equal 0, @parent.reload.replies_count
  end

  private
    def reply_to(message, by:, text: nil, html: nil)
      message.room.messages.create!(creator: users(by), body: html || text, parent_message: message)
    end
end
