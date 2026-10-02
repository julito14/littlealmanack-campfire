# A temporary "open seeding" mode: while it's on, the account's join code works as one
# reusable public sign-up link for any email address. Personal invitations keep working
# either way, and turning it off makes the public link 404 again immediately.
module Account::OpenSignup
  def open_signup_link?(token)
    open_signup? && ActiveSupport::SecurityUtils.secure_compare(join_code, token.to_s)
  end
end
