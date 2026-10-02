require "test_helper"

class OpenSignupTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:signal)
  end

  test "while off, the public link is not found" do
    get join_url(@account.join_code)
    assert_response :not_found
  end

  test "an admin turns it on, and anyone with the link can join with their own email" do
    sign_in :david
    post account_open_signup_url
    assert @account.reload.open_signup?
    delete session_url

    get join_url(@account.join_code)
    assert_response :success
    assert_select "input[name='user[email_address]']:not([readonly])"

    assert_difference -> { User.count }, 1 do
      post join_url(@account.join_code), params: { user: { name: "Seed Reader", email_address: " Seed@Example.com ", password: "secret123456" } }
    end
    assert_redirected_to root_url

    user = User.last
    assert_equal "seed@example.com", user.email_address
    assert_equal "open_link", user.joined_via
    assert_equal Rooms::Open.all.to_a.sort_by(&:id), user.rooms.to_a.sort_by(&:id)
  end

  test "the public link can be used again and again" do
    @account.update!(open_signup: true)

    %w[ one@example.com two@example.com ].each do |email|
      post join_url(@account.join_code), params: { user: { name: email, email_address: email, password: "secret123456" } }
      assert_redirected_to root_url
      delete session_url
    end
    assert_equal 2, User.where(joined_via: "open_link").count
  end

  test "joining with the public link fulfils a pending personal invitation for the same email" do
    @account.update!(open_signup: true)

    post join_url(@account.join_code), params: { user: { name: "Newcomer", email_address: invitations(:pending).email_address, password: "secret123456" } }

    assert invitations(:pending).reload.accepted?
    assert_equal User.last, invitations(:pending).user
  end

  test "an email that already has an account goes to sign in" do
    @account.update!(open_signup: true)

    assert_no_difference -> { User.count } do
      post join_url(@account.join_code), params: { user: { name: "Again", email_address: users(:jz).email_address, password: "secret123456" } }
    end
    assert_redirected_to new_session_url(email_address: users(:jz).email_address)
  end

  test "a missing or malformed email is refused" do
    @account.update!(open_signup: true)

    assert_no_difference -> { User.count } do
      post join_url(@account.join_code), params: { user: { name: "Bot", email_address: "not-an-email", password: "secret123456" } }
    end
    assert_response :unprocessable_entity
  end

  test "turning it off closes the public link right away" do
    @account.update!(open_signup: true)
    sign_in :david
    delete account_open_signup_url
    delete session_url

    get join_url(@account.join_code)
    assert_response :not_found
  end

  test "a new link replaces the old one" do
    @account.update!(open_signup: true)
    old_code = @account.join_code
    sign_in :david
    patch account_open_signup_url
    delete session_url

    get join_url(old_code)
    assert_response :not_found
    get join_url(@account.reload.join_code)
    assert_response :success
  end

  test "personal invitations keep working, email-locked, while it's on" do
    @account.update!(open_signup: true)

    post join_url(invitations(:pending).token), params: { user: { name: "Invited", email_address: "other@example.com", password: "secret123456" } }

    user = User.last
    assert_equal invitations(:pending).email_address, user.email_address
    assert_equal "invitation", user.joined_via
  end

  test "turning it on or off keeps the other account settings" do
    @account.update!(settings: { restrict_room_creation_to_administrators: true })
    sign_in :david
    post account_open_signup_url
    delete account_open_signup_url

    assert @account.reload.settings.restrict_room_creation_to_administrators?
  end

  test "only administrators see or control the public link" do
    @account.update!(open_signup: true)
    sign_in :jz

    get edit_account_url
    assert_no_match @account.join_code, response.body

    get account_invitations_url
    assert_response :forbidden
    post account_open_signup_url
    assert_response :forbidden
    patch account_open_signup_url
    assert_response :forbidden
    delete account_open_signup_url
    assert_response :forbidden
  end
end
