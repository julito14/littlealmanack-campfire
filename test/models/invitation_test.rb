require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "gets a random token and a normalized email address" do
    invitation = Invitation.create!(email_address: "  Reader@Example.COM ", creator: users(:david))

    assert_equal "reader@example.com", invitation.email_address
    assert_equal 24, invitation.token.length
  end

  test "requires a valid email address" do
    assert_not Invitation.new(email_address: "not an email", creator: users(:david)).valid?
  end

  test "can't invite an email address with a pending invitation" do
    invitation = Invitation.new(email_address: invitations(:pending).email_address, creator: users(:david))

    assert_not invitation.valid?
    assert_includes invitation.errors.full_messages, "Email address already has a pending invitation"
  end

  test "can't invite an existing member" do
    invitation = Invitation.new(email_address: users(:jz).email_address, creator: users(:david))

    assert_not invitation.valid?
    assert_includes invitation.errors.full_messages, "Email address already belongs to a member"
  end

  test "can invite someone again after they were removed" do
    users(:jz).deactivate

    assert Invitation.new(email_address: "jz@37signals.com", creator: users(:david)).valid?
  end

  test "accepting creates the user with the invited email address, whatever was submitted" do
    invitation = invitations(:pending)

    user = invitation.accept(name: "Newcomer", password: "secret123456", email_address: "someone-else@example.com")

    assert_equal "newcomer@example.com", user.email_address
    assert_equal user, invitation.reload.user
    assert invitation.accepted?
    assert_not_includes Invitation.pending, invitation
  end
end
