module Rooms::TitleHelper
  # The room name in the nav. In a one-on-one Ping the name is the other person,
  # so it shows their photo and opens their profile; everywhere else it stays a plain label.
  def room_title_tag(room, &)
    if person = one_on_one_counterpart(room)
      link_to user_path(person), class: "btn btn--reversed room--current gap" do
        # A background, not an <img>: an image inside a .btn turns it into a round icon button.
        photo = tag.span class: "avatar flex-item-no-shrink", aria: { hidden: "true" },
          style: "--avatar-size: 1.6em; background: center / cover url('#{fresh_user_avatar_path(person)}')"
        photo + capture(&)
      end
    else
      tag.span class: "btn btn--reversed btn--faux room--current", &
    end
  end

  private
    def one_on_one_counterpart(room)
      others = room.users.without(Current.user).to_a if room.direct?
      others.first if others&.one?
    end
end
