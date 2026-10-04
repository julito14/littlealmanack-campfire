require "test_helper"

class LocalChatsTest < ActionDispatch::IntegrationTest
  setup do
    users(:jz).update!(city: cities(:mumbai))
    users(:kevin).update!(city: cities(:ulhasnagar))
    @room = LocalChat.find(cities(:mumbai))
  end

  test "members who live there open it from the area's page, and it's in their rooms" do
    sign_in :kevin

    get city_url(cities(:mumbai))
    assert_select "a[href=?]", room_path(@room), text: /Open the Mumbai area chat/

    get user_sidebar_url
    assert_select "#shared_rooms a[href=?]", room_path(@room)
  end

  test "members who live elsewhere can't open it, and don't see the button" do
    users(:jason).update_columns(role: User.roles[:member])
    users(:jason).update!(city: cities(:barcelona))
    sign_in :jason

    get city_url(cities(:mumbai))
    assert_select "a[href=?]", room_path(@room), count: 0
    assert_select "form[action^='#{local_chats_path}']", count: 0
    assert_select ".nearby-page__person", count: 2 # still see who's there, to DM them one by one

    post local_chats_url(city_id: cities(:mumbai).id)
    assert_response :forbidden
  end

  test "administrators can open any area's chat, which adds them" do
    sign_in :david # an administrator, no city

    get city_url(cities(:mumbai))
    assert_select "form[action=?]", local_chats_path(city_id: cities(:mumbai).id), text: /Open the Mumbai area chat/

    post local_chats_url(city_id: cities(:mumbai).id)
    assert_redirected_to room_url(@room)
    assert_includes @room.reload.users, users(:david)
  end
end
