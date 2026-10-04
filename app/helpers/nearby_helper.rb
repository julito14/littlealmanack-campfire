module NearbyHelper
  # "Barcelona", or "Barcelona area" when it takes in members from cities around it.
  def nearby_label(city, people)
    people.map(&:city_id).uniq.many? ? "#{city.name} area" : city.name
  end

  # "You, Marta, Alex and 4 more"
  def nearby_names(people, viewer: Current.user)
    names = people.sort_by { |person| person == viewer ? 0 : 1 }.map { |person| person == viewer ? "You" : person.name.split.first }
    names.size > 4 ? "#{names.first(3).join(", ")} and #{names.size - 3} more" : names.to_sentence
  end

  # The area's chat, for the people who live there (and administrators, who join by opening it).
  # Everyone else can DM a member from their profile.
  def local_chat_button(city, people, viewer: Current.user)
    return unless viewer.administrator? || people.include?(viewer)
    return unless chat = LocalChat.find(city)

    content = image_tag("list-dms.svg", size: 18, aria: { hidden: "true" }) +
      tag.span("Open the #{chat.name.delete_prefix("📍").strip} chat")

    if chat.users.include?(viewer)
      link_to content, room_path(chat), class: "btn btn--reversed nearby__chat txt-small", data: { turbo_frame: "_top" }
    else
      button_to local_chats_path(city_id: city.id), class: "btn btn--reversed nearby__chat txt-small", form: { data: { turbo_frame: "_top" } } do
        content
      end
    end
  end
end
