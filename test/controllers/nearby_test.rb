require "test_helper"

class NearbyControllerTest < ActionDispatch::IntegrationTest
  test "the city search works before signing in, for the sign-up page" do
    get cities_url(format: :json), params: { q: "Bangalore" }

    assert_response :success
    first = response.parsed_body.first
    assert_equal [ "Bengaluru", "Karnataka, India", "Bangalore" ], first.values_at("name", "place", "alias")
  end

  test "Members has a Nearby view, asking for your city until you've added one" do
    sign_in :david
    get user_sidebar_url
    assert_select ".members-views__nearby .nearby-card--empty a[href=?]", user_profile_path(anchor: "city")

    users(:david).update!(city: cities(:mumbai))
    users(:jason).update!(city: cities(:ulhasnagar))
    get user_sidebar_url
    assert_select ".nearby-card__title", text: "Mumbai area"
    assert_select ".nearby-card a[href=?]", room_path(LocalChat.find(cities(:mumbai))), text: /Open the Mumbai area chat/
    assert_select ".nearby-place--country", text: /India\s+2 members/
  end

  test "a city page lists everyone within 50 km" do
    sign_in :david
    users(:david).update!(city: cities(:mumbai))
    users(:jason).update!(city: cities(:ulhasnagar))

    get city_url(cities(:mumbai))

    assert_response :success
    assert_select "h1", "Mumbai area"
    assert_select ".nearby-page__person", count: 2
    assert_select ".nearby-page__person", text: /Ulhasnagar · \d+ km/
  end

  test "back on a place page goes back the way you came, and otherwise up a level, never in a loop" do
    sign_in :david
    users(:david).update!(city: cities(:mumbai))

    get city_url(cities(:mumbai)), headers: { "Referer" => country_url("in") }
    assert_select "a[href=?][data-controller=history-back][data-turbo-action=replace]", country_path("in")

    get country_url("in"), headers: { "Referer" => city_url(cities(:mumbai)) }
    assert_select "a[href=?][data-controller=history-back]", root_path
  end

  test "a country page shows its areas and who hasn't set a city" do
    sign_in :david
    users(:jason).update!(city: cities(:pune))
    users(:kevin).update_columns(country_code: "IN")

    get country_url("in")

    assert_response :success
    assert_select ".nearby-place", text: /Pune\s+1/
    assert_select ".nearby-page__person", text: /Kevin/
  end

  test "members pick their city on their profile" do
    sign_in :david
    put user_profile_url, params: { user: { city_id: cities(:barcelona).id } }

    assert_equal "Barcelona, Spain", users(:david).reload.location
  end
end
