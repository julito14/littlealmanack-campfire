# Optional details members add on their settings page (where they are, some books they like,
# their site and social accounts) and that other members see on their profile page.
module User::ProfileDetails
  extend ActiveSupport::Concern

  ATTRIBUTES = %i[ location books website_url x_handle linkedin_url instagram_handle ]
  HANDLE = /\A[A-Za-z0-9_.]{1,30}\z/
  LINKEDIN_HOST = /(\A|\.)linkedin\.com\z/i

  included do
    normalizes :location, :books, with: ->(text) { text.strip.presence }
    normalizes :website_url, with: ->(value) { User::ProfileDetails.web_url_from(value) }
    normalizes :linkedin_url, with: ->(value) { User::ProfileDetails.linkedin_url_from(value) }
    normalizes :x_handle, :instagram_handle, with: ->(value) { User::ProfileDetails.handle_from(value) }

    validates :location, length: { maximum: 100, message: "Location can be up to 100 characters." }
    validates :books, length: { maximum: 300, message: "Books can be up to 300 characters in all." }
    validates :website_url, :linkedin_url, length: { maximum: 200, message: "Links can be up to 200 characters." }
    validates :x_handle, :instagram_handle, format: { with: HANDLE, message: "X and Instagram need a username, like @name." }, allow_nil: true
    validate :website_url_is_a_web_address, :linkedin_url_is_on_linkedin
  end

  class << self
    def web_url_from(value)
      value = value.strip
      value.match?(%r{\A[a-z][a-z0-9+.-]*://}i) ? value : "https://#{value}" if value.present?
    end

    def linkedin_url_from(value)
      value = value.strip
      return if value.blank?

      value.match?(/linkedin\.com/i) ? web_url_from(value) : "https://www.linkedin.com/in/#{value.delete_prefix("@")}"
    end

    # "@name", "name", and pasted profile links like "https://x.com/name" all become "name".
    def handle_from(value)
      value = value.strip.split(/[?#]/).first.to_s
      value = value.sub(%r{\A[a-z]+://}i, "").split("/").second.to_s if value.include?("/")
      value.delete_prefix("@").presence
    end
  end

  def books_list
    books.to_s.lines.map(&:strip).compact_blank
  end

  def profile_links
    {
      "Website"   => website_url,
      "X"         => (x_handle && "https://x.com/#{x_handle}"),
      "LinkedIn"  => linkedin_url,
      "Instagram" => (instagram_handle && "https://www.instagram.com/#{instagram_handle}")
    }.compact
  end

  private
    def website_url_is_a_web_address
      errors.add :website_url, "Website needs a web address, like yoursite.com." if website_url && !web_address?(website_url)
    end

    def linkedin_url_is_on_linkedin
      if linkedin_url && !web_address?(linkedin_url, host: LINKEDIN_HOST)
        errors.add :linkedin_url, "LinkedIn needs your profile link or username."
      end
    end

    def web_address?(url, host: nil)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) && uri.host.present? && (host.nil? || uri.host.match?(host))
    rescue URI::InvalidURIError
      false
    end
end
