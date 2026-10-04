require "test_helper"

class ThreadParticipationTest < ActiveSupport::TestCase
  include ActionCable::TestHelper, TurboTestHelper

  setup do
    @parent = messages(:first) # by Jason, in Designers
  end

  test "a reply brings in the starter, unread, and the replier, caught up" do
    reply_to @parent, by: :kevin, text: "Good point"

    assert participation(:jason).unread?
    assert_not participation(:kevin).unread?
    assert_nil participation(:david)
  end

  test "someone mentioned joins the thread and hears about later replies" do
    reply_to @parent, by: :kevin, html: "What do you think, #{mention_attachment_for(:jz)}?"
    participation(:jz).read

    later = reply_to @parent, by: :kevin, text: "Still curious"

    assert_includes later.thread_audience_ids, users(:jz).id
    assert participation(:jz).unread?
  end

  test "the thread keeps the time of its latest reply" do
    first = reply_to @parent, by: :kevin, text: "One"
    second = reply_to @parent, by: :david, text: "Two"
    assert_equal second.created_at, @parent.reload.last_reply_at

    second.destroy
    assert_equal first.created_at, @parent.reload.last_reply_at
  end

  test "a reply moves the thread up in every room member's list, bold only for those in it" do
    reply_to(@parent, by: :kevin, text: "Hi").broadcast_create

    rows = %i[ jason david ].index_with do |name|
      Nokogiri::HTML.fragment(find_broadcasts_for(users(name), :rooms)).at_css(%(turbo-stream[action="append"][target="thread_rows"]))
    end

    assert_includes rows[:jason].to_html, %(class="thread-row unread")
    assert_includes rows[:david].to_html, %(class="thread-row")
    assert_not_includes rows[:david].to_html, %(class="thread-row unread")
  end

  test "threads quiet for 30 days leave the list" do
    reply_to @parent, by: :kevin, text: "Old news"
    assert_includes Message.listed_threads, @parent

    @parent.update_column :last_reply_at, 31.days.ago
    assert_not_includes Message.listed_threads, @parent
  end

  private
    def reply_to(message, by:, text: nil, html: nil)
      message.room.messages.create!(creator: users(by), body: html || text, parent_message: message)
    end

    def participation(name)
      @parent.thread_participations.find_by(user: users(name))
    end
end
