require "test_helper"

class Rooms::TitleProfileLinkTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "in a one-on-one Ping, the name at the top opens the other person's profile" do
    get room_url(rooms(:david_and_jason))

    assert_select "a.room--current[href=?]", user_path(users(:jason)) do
      assert_select "h1", /Jason/
    end
  end

  test "in a regular room, the name at the top stays a plain label" do
    get room_url(rooms(:hq))

    assert_select "span.room--current h1"
    assert_select "a.room--current", count: 0
  end

  test "in a group Ping, there is no single profile to open" do
    post rooms_directs_url, params: { user_ids: users(:jason, :jz).map(&:id) }
    follow_redirect!

    assert_select "span.room--current h1"
    assert_select "a.room--current", count: 0
  end
end
