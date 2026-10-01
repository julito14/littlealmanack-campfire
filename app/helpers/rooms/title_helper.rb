module Rooms::TitleHelper
  # The room name in the nav. In a one-on-one Ping the name is the other person,
  # so it opens their profile; everywhere else it stays a plain label.
  def room_title_tag(room, &)
    if person = one_on_one_counterpart(room)
      link_to user_path(person), class: "btn btn--reversed room--current", &
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
