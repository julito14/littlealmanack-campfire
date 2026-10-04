require "test_helper"

class SignupDetailsTest < ActionDispatch::IntegrationTest
  test "the signup page offers bio, city, books, X, and Instagram as optional fields" do
    get join_url(invitations(:pending).token)

    assert_select "textarea[name='user[bio]']:not([required])"
    assert_select "input[type=hidden][name='user[city_id]']"
    assert_select "input[role=combobox][placeholder=?]:not([required])", "Your city (optional)"
    assert_select "input[name='user[location]']", count: 0
    assert_select "textarea[name='user[books]']:not([required])"
    assert_select "input[name='user[x_handle]'][placeholder='@username']:not([required])"
    assert_select "input[name='user[instagram_handle]'][placeholder='@username']:not([required])"
    assert_select "input[name='user[website_url]']", count: 0
    assert_select "input[name='user[linkedin_url]']", count: 0
  end

  test "X and Instagram given at signup are saved, whether typed as @name or pasted as a link" do
    post join_url(invitations(:pending).token), params: { user: {
      name: "Newcomer", password: "secret123456", x_handle: "@reader", instagram_handle: "https://www.instagram.com/reader.books/" } }

    user = User.last
    assert_equal "reader", user.x_handle
    assert_equal "reader.books", user.instagram_handle
  end

  test "an invalid username at signup is explained and nothing is created" do
    assert_no_difference -> { User.count } do
      post join_url(invitations(:pending).token), params: { user: { name: "Newcomer", password: "secret123456", x_handle: "two words" } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", /need a username/
  end

  test "details given at signup are saved with an invitation" do
    post join_url(invitations(:pending).token), params: { user: {
      name: "Newcomer", password: "secret123456", bio: "Slow reader.", city_id: cities(:barcelona).id, books: "Meditations\nWalden" } }

    user = User.last
    assert_equal "Slow reader.", user.bio
    assert_equal [ cities(:barcelona), "Barcelona, Spain", "ES" ], [ user.city, user.location, user.country_code ]
    assert_equal [ "Meditations", "Walden" ], user.books_list
  end

  test "details given at signup are saved with the open link" do
    accounts(:signal).update!(open_signup: true)

    post join_url(accounts(:signal).join_code), params: { user: {
      name: "Seed", email_address: "seed@example.com", password: "secret123456", city_id: cities(:new_york).id } }

    assert_equal "New York City, United States", User.find_by!(email_address: "seed@example.com").location
  end

  test "everything optional can be left empty" do
    post join_url(invitations(:pending).token), params: { user: { name: "Newcomer", password: "secret123456", bio: "", city_id: "", books: "" } }

    assert_redirected_to root_url
    assert_nil User.last.location
  end

  test "something that can't be saved is explained, what was typed is kept, and nothing is created" do
    assert_no_difference -> { User.count } do
      post join_url(invitations(:pending).token), params: { user: {
        name: "Newcomer", password: "secret123456", bio: "Keep me", books: "x" * 301 } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", /up to 300 characters/
    assert_select "textarea[name='user[bio]']", text: "Keep me"
    assert_not invitations(:pending).reload.accepted?
  end
end
