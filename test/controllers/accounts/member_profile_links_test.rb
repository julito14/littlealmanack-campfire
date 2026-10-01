require "test_helper"

# The member list in account settings doubles as a directory: names open profiles.
class Accounts::MemberProfileLinksTest < ActionDispatch::IntegrationTest
  test "members can open anyone's profile from the member list" do
    sign_in :jz
    get edit_account_url

    users(:david, :jason, :kevin).each do |user|
      assert_select "a[href=?][data-turbo-frame=_top]", user_path(user), text: user.name
    end
  end
end
