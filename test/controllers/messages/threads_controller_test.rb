require "test_helper"

class Messages::ThreadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "once.campfire.test"
    sign_in :david

    @room = rooms(:designers)
    @parent = messages(:first)
    @reply = @room.messages.create!(creator: users(:kevin), body: "A reply in the thread", parent_message: @parent)
  end

  test "the thread shows its opening message and the replies" do
    get room_message_thread_url(@room, @parent)

    assert_response :success
    assert_select "#" + dom_id(@parent, :replies) do
      assert_select "#" + dom_id(@parent)
      assert_select "#" + dom_id(@reply)
      assert_select "#" + dom_id(@parent, :replies_count), text: /1 reply/
    end
    assert_select "form#composer[action=?]", room_messages_path(@room, thread_id: @parent.id)
  end

  test "a link to a reply opens its thread at that reply" do
    get room_at_message_url(@room, @reply)

    assert_redirected_to room_message_thread_at_reply_url(@room, @parent, @reply)

    follow_redirect!
    assert_response :success
    assert_select "#" + dom_id(@reply)
  end

  test "the room shows a summary instead of the replies" do
    get room_url(@room)

    assert_response :success
    assert_select "#" + dom_id(@reply), count: 0
    assert_select "#" + dom_id(@parent, :thread_summary), text: /1 reply/
  end

  test "people outside the room can't open its threads" do
    sign_in :kevin # not in All Talk

    assert_raises(ActiveRecord::RecordNotFound) { get room_message_thread_url(rooms(:watercooler), messages(:fourth)) }
  end

  test "pings have no threads" do
    ping = rooms(:david_and_kevin).messages.create!(creator: users(:david), body: "Psst")

    get room_message_thread_url(rooms(:david_and_kevin), ping)

    assert_redirected_to room_at_message_url(rooms(:david_and_kevin), ping)
  end

  test "replying adds to the thread, live, and refreshes the summary in the room" do
    assert_difference -> { @parent.reload.replies_count }, +1 do
      post room_messages_url(@room, thread_id: @parent.id, format: :turbo_stream), params: { message: { body: "Me too", client_message_id: "me-too" } }
    end

    reply = Message.find_by!(client_message_id: "me-too")
    assert_equal @parent, reply.parent_message
    assert_select "turbo-stream[action='append'][target='#{dom_id(@parent, :replies)}']"

    assert_rendered_turbo_stream_broadcast @room, :messages, action: "append", target: [ @parent, :replies ] do
      assert_select ".message__body", text: /Me too/
    end
    assert_rendered_turbo_stream_broadcast @room, :messages, action: "replace", target: [ @parent, :thread_summary ] do
      assert_select ".thread-summary", text: /2 replies/
    end
  end

  test "a reply only flags the room as unread for the thread" do
    assert_broadcasts UnreadRoomsChannel.stream_name_for(users(:jason).id), 1 do
      assert_no_broadcasts UnreadRoomsChannel.stream_name_for(users(:jz).id) do
        post room_messages_url(@room, thread_id: @parent.id, format: :turbo_stream), params: { message: { body: "For the thread", client_message_id: "thread-only" } }
      end
    end
  end

  test "the room pages through its own messages and the thread through its replies" do
    get room_messages_url(@room)
    assert_select "#" + dom_id(@reply), count: 0
    assert_select "#" + dom_id(@parent)

    get room_messages_url(@room, thread_id: @parent.id)
    assert_select "#" + dom_id(@reply)
    assert_select "#" + dom_id(@parent), count: 0
  end

  test "a refresh of the thread brings its new replies" do
    get room_refresh_url(@room, format: :turbo_stream), params: { since: 10.minutes.ago.to_fs(:epoch), thread_id: @parent.id }

    assert_select "turbo-stream[action='append'][target='#{dom_id(@parent, :replies)}']" do
      assert_select "#" + dom_id(@reply)
    end
  end

  test "a refresh of the room leaves replies out" do
    get room_refresh_url(@room, format: :turbo_stream), params: { since: 10.minutes.ago.to_fs(:epoch) }

    assert_select "turbo-stream[action='append'] #" + dom_id(@reply), count: 0
  end
end
