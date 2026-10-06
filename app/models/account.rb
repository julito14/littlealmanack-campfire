class Account < ApplicationRecord
  include Joinable, OpenSignup

  has_one_attached :logo do |attachable|
    attachable.variant :large, resize_to_limit: [ 512, 512 ], format: :png
    attachable.variant :small, resize_to_limit: [ 192, 192 ], format: :png
  end

  has_json :settings, restrict_room_creation_to_administrators: false

  # The "Support & tips" page at the bottom of Rooms; until an administrator edits it, members
  # see the starting text in app/views/support_pages/_default.html.erb.
  has_rich_text :support_text

  def logo_variant(size)
    logo.variant(size).processed if logo.variable?
  end
end
