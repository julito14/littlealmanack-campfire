require "test_helper"

class Users::RoomOrderTest < ActionDispatch::IntegrationTest
  test "a local chat sits right after the first room" do
    rooms(:watercooler).update_columns(position: 1)
    rooms(:pets).update_columns(position: 2)
    users(:david).update!(city: cities(:mumbai))
    users(:jason).update!(city: cities(:ulhasnagar))

    sign_in :david
    get user_sidebar_url

    names = css_select("#shared_rooms .room").map { |room| room.text.squish }
    assert_equal [ "All Talk", "📍 Mumbai area", "All Pets" ], names.first(3)
  end

  test "rooms put in order come first, in that order, then the rest alphabetically" do
    rooms(:watercooler).update_columns(position: 1) # "All Talk"
    rooms(:pets).update_columns(position: 2)        # "All Pets"

    sign_in :david
    get user_sidebar_url

    names = css_select("#shared_rooms .room").map { |room| room.text.squish }
    assert_equal [ "All Talk", "All Pets" ], names.first(2)
    assert_equal names.drop(2).sort_by(&:downcase), names.drop(2)

    keys = css_select("#shared_rooms .room").map { |room| room["data-sorted-list-name"] }
    assert_equal keys.sort, keys, "the sidebar re-sorts by this key as rooms update"
  end
end
