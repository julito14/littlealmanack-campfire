require "test_helper"

class Users::ProfileDetailsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :jz
  end

  test "members fill in their details on their settings page" do
    get user_profile_url
    assert_select "input[name='user[location]'][placeholder=?]", "Location (e.g. New York, US)"
    assert_select "textarea[name='user[books]']"
    assert_select "input[name='user[website_url]']"

    put user_profile_url, params: { user: {
      location: "Barcelona, Spain", books: "Poor Charlie's Almanack", website_url: "littlealmanack.com",
      x_handle: "@reader", linkedin_url: "reader", instagram_handle: "reader" } }

    assert_redirected_to user_profile_url
    user = users(:jz).reload
    assert_equal "Barcelona, Spain", user.location
    assert_equal "Poor Charlie's Almanack", user.books
    assert_equal "https://littlealmanack.com", user.website_url
    assert_equal "reader", user.x_handle
    assert_equal "https://www.linkedin.com/in/reader", user.linkedin_url
    assert_equal "reader", user.instagram_handle
  end

  test "a bad link is explained and nothing is saved" do
    put user_profile_url, params: { user: { location: "Lisbon", website_url: "javascript:alert(1)" } }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", /web address/
    assert_nil users(:jz).reload.location
  end

  test "other members see the details on the profile page, with safe links" do
    users(:jz).update!(location: "Barcelona, Spain", books: "Poor Charlie's Almanack\n<script>alert(1)</script>",
      website_url: "littlealmanack.com", x_handle: "reader")

    sign_in :kevin
    get user_url(users(:jz))

    assert_select "div", text: "Barcelona, Spain"
    assert_select "div", text: "Poor Charlie's Almanack"
    assert_no_match "<script>alert(1)</script>", response.body
    assert_select "a[href='https://littlealmanack.com'][target=_blank][rel~=noopener]", text: /Website/
    assert_select "a[href='https://x.com/reader']", text: /X/
    assert_select "a", text: /LinkedIn/, count: 0
  end

  test "empty details don't show" do
    sign_in :kevin
    get user_url(users(:jz))

    assert_no_match "Some books I like", response.body
  end
end
