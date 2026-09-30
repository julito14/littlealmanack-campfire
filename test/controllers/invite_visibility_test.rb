require "test_helper"

# Members must never be shown a way to bring people in; only administrators can invite.
class InviteVisibilityTest < ActionDispatch::IntegrationTest
  setup do
    @room = Room.original
    @room.memberships.grant_to users(:jz) unless @room.users.include?(users(:jz))
    @room.messages.destroy_all # the welcome note only shows while the room is short
  end

  test "members see no invite link in account settings" do
    sign_in :jz
    get edit_account_url

    assert_response :ok
    assert_select "a[href=?]", account_invitations_path, count: 0
    assert_no_match %r{/join/}, response.body
  end

  test "administrators get to invitations from account settings" do
    sign_in :david
    get edit_account_url

    assert_select "a[href=?]", account_invitations_path
  end

  test "members don't get the invite welcome note in the first room" do
    sign_in :jz
    get room_url(@room)

    assert_response :ok
    assert_select "#system_welcome", count: 0
    assert_no_match %r{/join/}, response.body
  end

  test "administrators get the invite welcome note in the first room" do
    sign_in :david
    get room_url(@room)

    assert_select "#system_welcome a[href=?]", account_invitations_path
  end
end
