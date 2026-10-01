require "test_helper"

class Sessions::EmailCaseTest < ActionDispatch::IntegrationTest
  test "signing in ignores capitals and stray spaces in the email address" do
    [ "DAVID@37signals.com", "David@37Signals.COM", " david@37signals.com " ].each do |typed|
      post session_url, params: { email_address: typed, password: "secret123456" }

      assert_redirected_to root_url, "#{typed.inspect} should sign in"
      delete session_url
    end
  end

  test "the password is still checked" do
    post session_url, params: { email_address: "DAVID@37signals.com", password: "wrong" }
    assert_response :unauthorized
  end

  test "email addresses are stored in lowercase" do
    user = User.create!(name: "Reader", email_address: " Reader@Example.COM ", password: "secret123456")
    assert_equal "reader@example.com", user.email_address

    users(:jz).update!(email_address: "JZ@37signals.com")
    assert_equal "jz@37signals.com", users(:jz).reload.email_address
  end
end
