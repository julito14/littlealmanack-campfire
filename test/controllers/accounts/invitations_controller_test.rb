require "test_helper"

class Accounts::InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "index lists pending invitations with their links" do
    get account_invitations_url

    assert_response :ok
    assert_select "input[value=?]", join_url(invitations(:pending).token)
    assert_match invitations(:accepted).email_address, response.body
  end

  test "create" do
    assert_difference -> { Invitation.pending.count }, 1 do
      post account_invitations_url, params: { invitation: { email_address: "reader@example.com" } }
    end

    assert_redirected_to account_invitations_url
    assert_equal users(:david), Invitation.last.creator
  end

  test "create shows why an invitation can't be made" do
    assert_no_difference -> { Invitation.count } do
      post account_invitations_url, params: { invitation: { email_address: users(:jz).email_address } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", /already belongs to a member/
  end

  test "destroy revokes a pending invitation" do
    delete account_invitation_url(invitations(:pending))

    assert_redirected_to account_invitations_url
    assert_not Invitation.exists?(invitations(:pending).id)
  end

  test "accepted invitations can't be revoked" do
    assert_raises ActiveRecord::RecordNotFound do
      delete account_invitation_url(invitations(:accepted))
    end

    assert Invitation.exists?(invitations(:accepted).id)
  end

  test "only administrators can see or make invitations" do
    sign_in :jz

    get account_invitations_url
    assert_response :forbidden

    assert_no_difference -> { Invitation.count } do
      post account_invitations_url, params: { invitation: { email_address: "friend@example.com" } }
    end
    assert_response :forbidden

    delete account_invitation_url(invitations(:pending))
    assert_response :forbidden
  end
end
