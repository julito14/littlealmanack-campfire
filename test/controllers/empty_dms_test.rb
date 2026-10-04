require "test_helper"

class EmptyDmsTest < ActionDispatch::IntegrationTest
  include TurboTestHelper

  setup do
    sign_in :david
  end

  test "tapping someone opens a DM without putting it in anyone's list yet" do
    post rooms_directs_url, params: { user_ids: [ users(:jz).id ] }
    room = Rooms::Direct.last

    assert_redirected_to room_url(room)
    assert_empty find_broadcasts_for(users(:jz), :rooms)

    get user_sidebar_url
    assert_select "#direct_rooms ##{dom_id(room, :list)}", count: 0
  end

  test "the first message puts the DM in both people's lists" do
    post rooms_directs_url, params: { user_ids: [ users(:jz).id ] }
    room = Rooms::Direct.last

    post room_messages_url(room, format: :turbo_stream), params: { message: { body: "Hi JZ", client_message_id: "first-dm" } }

    [ users(:david), users(:jz) ].each do |member|
      assert_select Nokogiri::HTML.fragment(find_broadcasts_for(member, :rooms)), %(turbo-stream[action="prepend"][target="direct_rooms"])
    end

    get user_sidebar_url
    assert_select "#direct_rooms ##{dom_id(room, :list)}"
  end
end
