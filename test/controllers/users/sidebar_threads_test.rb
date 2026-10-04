require "test_helper"

class Users::SidebarThreadsTest < ActionDispatch::IntegrationTest
  setup do
    @room = rooms(:designers)
    @parent = messages(:first) # by Jason
    @room.messages.create!(creator: users(:kevin), body: "A reply", parent_message: @parent)
  end

  test "the menu has Rooms, DMs, Threads and Members, and starts on Rooms" do
    sign_in :david
    get user_sidebar_url

    assert_select ".sidebar-lists__tab", count: 4
    assert_select ".sidebar-lists__tab:first-child[data-name=rooms]"
    assert_select "#rooms_list:not([hidden]) #shared_rooms"
    assert_select "#dms_list[hidden]"
    assert_select "#dms_list a[href=?]", new_rooms_direct_path
    assert_select "#members_list .sidebar-lists__member", count: User.active.without_bots.count
    assert_select "#members_list a[href=?]", user_path(users(:kevin))
  end

  test "Threads lists every thread in the member's rooms, bold only where they're in it" do
    sign_in :jason
    get user_sidebar_url
    assert_select "#thread_rows ##{dom_id(@parent, :thread_row)}.unread[href=?]", room_message_thread_path(@room, @parent) do
      assert_select ".thread-row__room", text: @room.name
      assert_select ".thread-row__meta", text: /1 reply/
    end

    sign_in :david
    get user_sidebar_url
    assert_select "#thread_rows ##{dom_id(@parent, :thread_row)}:not(.unread)"
  end

  test "threads from rooms the member isn't in stay out of the list" do
    watercooler_thread = messages(:fourth)
    rooms(:watercooler).messages.create!(creator: users(:jason), body: "Hidden", parent_message: watercooler_thread)

    sign_in :kevin # not in All Talk
    get user_sidebar_url

    assert_select "##{dom_id(watercooler_thread, :thread_row)}", count: 0
  end

  test "opening the thread marks it read" do
    sign_in :jason
    get room_message_thread_url(@room, @parent)

    get user_sidebar_url
    assert_select "##{dom_id(@parent, :thread_row)}:not(.unread)"
  end

  test "hovering a thread link (Turbo prefetching it) doesn't mark it read" do
    sign_in :jason
    get room_message_thread_url(@room, @parent), headers: { "X-Sec-Purpose" => "prefetch" }

    assert @parent.thread_participations.find_by(user: users(:jason)).unread?
  end

  test "an open thread page marks new replies read as they arrive" do
    sign_in :jason
    @room.messages.create!(creator: users(:kevin), body: "Another", parent_message: @parent)

    post room_message_thread_reading_url(@room, @parent)

    assert_response :no_content
    assert_not @parent.thread_participations.find_by(user: users(:jason)).unread?
  end
end
