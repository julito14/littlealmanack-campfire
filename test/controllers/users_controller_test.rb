require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @invitation = invitations(:pending)
  end

  test "show" do
    sign_in :david
    get user_url(users(:david))
    assert_response :ok
  end

  test "new shows the invited email address" do
    get join_url(@invitation.token)

    assert_response :success
    assert_select "input[name='user[email_address]'][readonly][value=?]", @invitation.email_address
  end

  test "new does not allow a signed in user" do
    sign_in :david

    get join_url(@invitation.token)
    assert_redirected_to root_url
  end

  test "new requires a valid invitation" do
    get join_url("not")
    assert_response :not_found
  end

  test "the account-wide join code no longer works" do
    get join_url(accounts(:signal).join_code)
    assert_response :not_found
  end

  test "a used invitation no longer works" do
    get join_url(invitations(:accepted).token)
    assert_response :not_found

    assert_no_difference -> { User.count } do
      post join_url(invitations(:accepted).token), params: { user: { name: "Gatecrasher", password: "secret123456" } }
    end
    assert_response :not_found
  end

  test "create" do
    assert_difference -> { User.count }, 1 do
      post join_url(@invitation.token), params: { user: { name: "New Person", password: "secret123456" } }
    end

    assert_redirected_to root_url

    user = User.last
    assert_equal user.id, Session.find_by(token: parsed_cookies.signed[:session_token]).user.id
    assert_equal Rooms::Open.all, user.rooms
    assert_equal user, @invitation.reload.user
  end

  test "create uses the invited email address, not a submitted one" do
    post join_url(@invitation.token), params: { user: { name: "Forwarded To", email_address: "friend@example.com", password: "secret123456" } }

    assert_equal "newcomer@example.com", User.last.email_address
    assert_not User.exists?(email_address: "friend@example.com")
  end

  test "an invitation can only be used once" do
    post join_url(@invitation.token), params: { user: { name: "New Person", password: "secret123456" } }
    delete session_url

    assert_no_difference -> { User.count } do
      post join_url(@invitation.token), params: { user: { name: "Second Person", password: "secret123456" } }
    end
    assert_response :not_found
  end

  test "joining with an email address that already has an account redirects to the login screen" do
    User.create!(name: "Early Bird", email_address: @invitation.email_address, password: "secret123456")

    assert_no_difference -> { User.count } do
      post join_url(@invitation.token), params: { user: { name: "Newcomer", password: "secret123456" } }
    end

    assert_redirected_to new_session_url(email_address: @invitation.email_address)
  end
end
