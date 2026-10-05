require "test_helper"

class LocalChatTest < ActiveSupport::TestCase
  test "it starts itself when a second member lives nearby, named after the area's biggest city" do
    users(:jz).update!(city: cities(:mumbai))
    assert_nil LocalChat.find(cities(:mumbai)), "one member is no one to chat with"

    users(:kevin).update!(city: cities(:ulhasnagar))
    room = LocalChat.find(cities(:ulhasnagar))

    assert room.is_a?(Rooms::Closed)
    assert_equal [ "📍 Mumbai area", cities(:mumbai), LocalChat.host ], [ room.name, room.city, room.creator ]
    assert_equal [ users(:jz), users(:kevin) ].sort_by(&:id), room.users.sort_by(&:id)
    assert_match "within 50 km of Mumbai", room.messages.first.plain_text_body
    assert_match "👋 Kevin is now in Ulhasnagar. Say hi!", room.messages.last.plain_text_body
  end

  test "there's one chat per area, and someone who moves in later joins with a hello" do
    users(:jz).update!(city: cities(:mumbai))
    users(:kevin).update!(city: cities(:ulhasnagar))
    room = LocalChat.find(cities(:mumbai))

    users(:david).update!(city: cities(:mumbai))

    assert_equal 1, Rooms::Closed.locals.count
    assert_includes room.reload.users, users(:david)
    assert_match "👋 David", room.messages.last.plain_text_body
  end

  test "switching city away and back within a day isn't announced twice" do
    users(:jz).update!(city: cities(:mumbai))
    users(:kevin).update!(city: cities(:ulhasnagar))
    room = LocalChat.find(cities(:mumbai))

    users(:kevin).update!(city: cities(:pune))
    users(:kevin).update!(city: cities(:mumbai))

    assert_includes room.reload.users, users(:kevin)
    assert_equal 1, room.messages.count { |message| message.plain_text_body.start_with?("👋 Kevin ") }
  end

  test "the club account has the club's book as its picture" do
    assert LocalChat.host.avatar.attached?
    assert LocalChat.host.bot?
  end

  test "moving away leaves the chat, unless you're an administrator" do
    users(:jz).update!(city: cities(:mumbai))
    users(:kevin).update!(city: cities(:ulhasnagar))
    room = LocalChat.find(cities(:mumbai))
    LocalChat.open!(cities(:mumbai), by: users(:david)) # an administrator opening it from afar

    users(:kevin).update!(city: cities(:pune))
    users(:david).update!(city: cities(:barcelona))

    assert_not_includes room.reload.users, users(:kevin)
    assert_includes room.users, users(:david)
  end

  test "chats for areas that already had members start in one go" do
    users(:jz).update_columns(city_id: cities(:mumbai).id)
    users(:kevin).update_columns(city_id: cities(:ulhasnagar).id)
    users(:jason).update_columns(city_id: cities(:pune).id) # alone in Pune

    started = LocalChat.start_everywhere

    assert_equal [ "📍 Mumbai area" ], started.map(&:name)
    assert_empty LocalChat.start_everywhere, "running it again starts nothing new"
  end
end
