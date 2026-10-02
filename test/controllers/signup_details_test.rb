require "test_helper"

class SignupDetailsTest < ActionDispatch::IntegrationTest
  test "the signup page offers bio, location, and books as optional fields" do
    get join_url(invitations(:pending).token)

    assert_select "textarea[name='user[bio]']:not([required])"
    assert_select "input[name='user[location]']:not([required])"
    assert_select "textarea[name='user[books]']:not([required])"
    assert_select "input[name='user[website_url]']", count: 0
  end

  test "details given at signup are saved with an invitation" do
    post join_url(invitations(:pending).token), params: { user: {
      name: "Newcomer", password: "secret123456", bio: "Slow reader.", location: "Lisbon, PT", books: "Meditations\nWalden" } }

    user = User.last
    assert_equal "Slow reader.", user.bio
    assert_equal "Lisbon, PT", user.location
    assert_equal [ "Meditations", "Walden" ], user.books_list
  end

  test "details given at signup are saved with the open link" do
    accounts(:signal).update!(open_signup: true)

    post join_url(accounts(:signal).join_code), params: { user: {
      name: "Seed", email_address: "seed@example.com", password: "secret123456", location: "Tokyo, JP" } }

    assert_equal "Tokyo, JP", User.find_by!(email_address: "seed@example.com").location
  end

  test "everything optional can be left empty" do
    post join_url(invitations(:pending).token), params: { user: { name: "Newcomer", password: "secret123456", bio: "", location: "", books: "" } }

    assert_redirected_to root_url
    assert_nil User.last.location
  end

  test "something that can't be saved is explained, what was typed is kept, and nothing is created" do
    assert_no_difference -> { User.count } do
      post join_url(invitations(:pending).token), params: { user: {
        name: "Newcomer", password: "secret123456", bio: "Keep me", location: "x" * 61 } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", /up to 60 characters/
    assert_select "textarea[name='user[bio]']", text: "Keep me"
    assert_not invitations(:pending).reload.accepted?
  end
end
