require "test_helper"

class NearbyTest < ActiveSupport::TestCase
  setup do
    users(:david).update!(city: cities(:mumbai))
    users(:jason).update!(city: cities(:ulhasnagar))
    users(:jz).update!(city: cities(:pune))
    users(:kevin).update_columns(country_code: "IN") # said India, no city
  end

  test "an area takes in members' cities within 50 km, named after the biggest" do
    india = Nearby.new.country("IN")

    assert_equal [ "Mumbai area", "Pune" ], india.areas.map(&:label)
    assert_equal [ 2, 1 ], india.areas.map(&:size)
    assert_equal [ users(:kevin) ], india.members_without_city
    assert_equal 4, india.size
  end

  test "around a city: everyone within 50 km, nearest first" do
    around = Nearby.new.around(cities(:mumbai))

    assert_equal [ users(:david), users(:jason) ], around.map(&:first)
    assert_in_delta 32, around.last.last, 3
  end

  test "countries come biggest first" do
    users(:david).update!(city: cities(:barcelona))

    assert_equal [ "IN", "ES" ], Nearby.new.countries.map(&:code)
  end
end
