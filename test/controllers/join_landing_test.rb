require "test_helper"

class JoinLandingTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:signal)
  end

  test "while open sign-up is on, /join forwards to the current sign-up page" do
    @account.update!(open_signup: true)

    get join_landing_url
    assert_redirected_to join_url(@account.join_code)
  end

  test "after a new link, /join follows it" do
    @account.update!(open_signup: true)
    @account.reset_join_code

    get join_landing_url
    assert_redirected_to join_url(@account.reload.join_code)
  end

  test "while it's off, /join shows a friendly closed page without revealing any link" do
    get join_landing_url

    assert_response :success
    assert_match "isn't open for new sign-ups", response.body
    assert_select "a[href=?]", new_session_path
    assert_no_match @account.join_code, response.body
  end

  test "while it's off, /join can send visitors elsewhere, like a checkout page" do
    @account.update!(closed_signup_url: "pay.example.com/bookclub")

    get join_landing_url
    assert_redirected_to "https://pay.example.com/bookclub"
  end

  test "while it's on, the closed-sign-up address is ignored" do
    @account.update!(open_signup: true, closed_signup_url: "https://pay.example.com/bookclub")

    get join_landing_url
    assert_redirected_to join_url(@account.join_code)
  end

  test "an admin sets and clears the closed-sign-up address" do
    sign_in :david

    patch account_signup_redirect_url, params: { account: { closed_signup_url: "pay.example.com/bookclub" } }
    assert_redirected_to account_invitations_url
    assert_equal "https://pay.example.com/bookclub", @account.reload.closed_signup_url

    patch account_signup_redirect_url, params: { account: { closed_signup_url: "" } }
    assert_nil @account.reload.closed_signup_url
  end

  test "only real web addresses are accepted" do
    sign_in :david

    patch account_signup_redirect_url, params: { account: { closed_signup_url: "javascript:alert(1)" } }

    assert_nil @account.reload.closed_signup_url
    assert_match "doesn't look like a web address", flash[:alert]
  end

  test "the invitations page shows the link to share" do
    sign_in :david
    get account_invitations_url

    assert_select "input[value=?]", join_landing_url
  end

  test "members can't change where /join goes" do
    sign_in :jz

    patch account_signup_redirect_url, params: { account: { closed_signup_url: "https://evil.example" } }
    assert_response :forbidden
    assert_nil @account.reload.closed_signup_url
  end
end
