require "test_helper"

class WelcomeNoteTest < ActionDispatch::IntegrationTest
  setup do
    @hi = rooms(:hq)
    @hi.update_columns(created_at: 1.year.ago, name: "👋 Hi") # the first room, where new members land
    users(:kevin).update_columns(welcomed_at: nil)
    sign_in :kevin
  end

  test "a new member is welcomed in the room they land in" do
    get room_url(@hi)

    assert_select "dialog.welcome-note" do
      assert_select "h2", "Welcome to #{accounts(:signal).name}!"
      assert_select "li", text: /Introduce yourself\s+here in\s+the Hi room/
      assert_select "a[href=?]", support_page_path, text: "Support & tips"
      assert_select "a[href=?]", room_path(@hi), count: 0
    end
  end

  test "elsewhere, it points to the Hi room" do
    get room_url(rooms(:designers))

    assert_select "dialog.welcome-note a[href=?]", room_path(@hi), text: "Hi"
  end

  test "it's shown once, on any device" do
    post welcome_note_url
    assert_response :no_content
    assert users(:kevin).reload.welcomed_at

    get room_url(@hi)
    assert_select "dialog.welcome-note", count: 0
  end

  test "members who were already here don't see it" do
    sign_in :jz
    get room_url(@hi)

    assert_select "dialog.welcome-note", count: 0
  end

  test "someone who just signed up gets it" do
    reset! # signed out
    post join_url(invitations(:pending).token), params: { user: { name: "Newcomer", password: "secret123456" } }

    assert_nil User.find_by!(name: "Newcomer").welcomed_at
  end
end
