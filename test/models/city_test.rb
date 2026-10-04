require "test_helper"

class CityTest < ActiveSupport::TestCase
  test "search finds cities by their other names, biggest first" do
    assert_equal cities(:new_york), City.search("nyc").first
    assert_equal cities(:bengaluru), City.search("Bangalore").first
    assert_equal cities(:mumbai), City.search("Mum").first
    assert_empty City.search("m")
  end

  test "an alternate name is shown only when it was typed in full" do
    assert_equal "Bangalore", cities(:bengaluru).alias_matching("bangalore")
    assert_nil cities(:bengaluru).alias_matching("Bang")
    assert_nil cities(:bengaluru).alias_matching("Beng")
  end

  test "distance between cities" do
    assert_in_delta 32, cities(:mumbai).distance_to(cities(:ulhasnagar)), 3
  end

  test "reading old free-text locations" do
    assert_equal cities(:pune), City::LocationMatch.new("Pune, india").city
    assert_equal cities(:bengaluru), City::LocationMatch.new("Bangalore, India").city
    assert_equal cities(:new_york), City::LocationMatch.new("NYC, USA").city
    assert_equal cities(:fremont), City::LocationMatch.new("Fremont, CA").city # California, not Canada

    netherlands = City::LocationMatch.new("Netherlands")
    assert_equal [ :country, "NL" ], [ netherlands.outcome, netherlands.country_code ]

    assert_equal :unsure, City::LocationMatch.new("Fremont, UL").outcome
    assert_equal :unsure, City::LocationMatch.new("San Ramkn, CA").outcome
  end

  test "a member's location and country follow the city they pick" do
    kevin = users(:kevin)
    kevin.update!(city: cities(:barcelona))
    assert_equal [ "Barcelona, Spain", "ES" ], [ kevin.location, kevin.country_code ]

    kevin.update!(city: nil)
    assert_equal [ nil, nil ], [ kevin.location, kevin.country_code ]
  end

  test "an old free-text location stays until a city is picked" do
    kevin = users(:kevin)
    kevin.update!(location: "Somewhere nice")
    kevin.update!(bio: "Reader")

    assert_equal "Somewhere nice", kevin.reload.location
  end
end
