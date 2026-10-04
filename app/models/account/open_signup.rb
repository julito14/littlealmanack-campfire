# A temporary "open seeding" mode: while it's on, the account's join code works as one
# reusable public sign-up link for any email address. Personal invitations keep working
# either way, and turning it off makes the public link 404 again immediately.
#
# /join is the permanent address to share: it forwards to the current public link while
# open sign-up is on, and otherwise to closed_signup_url (e.g. a checkout page) if set.
module Account::OpenSignup
  extend ActiveSupport::Concern

  included do
    normalizes :closed_signup_url, with: ->(url) { url.strip.then { |u| u.match?(%r{\A[a-z][a-z0-9+.-]*://}i) ? u : "https://#{u}" if u.present? } }
    validate :closed_signup_url_is_a_web_address
  end

  def open_signup_link?(token)
    open_signup? && ActiveSupport::SecurityUtils.secure_compare(join_code, token.to_s)
  end

  private
    def closed_signup_url_is_a_web_address
      return if closed_signup_url.blank?

      uri = URI.parse(closed_signup_url)
      errors.add :closed_signup_url, "needs to be a web address, like yoursite.com/join" unless uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      errors.add :closed_signup_url, "needs to be a web address, like yoursite.com/join"
    end
end
