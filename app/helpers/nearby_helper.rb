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

  # One group DM with everyone else in the place, or the DM with them if there's just one.
  def button_to_dm_everyone(people, viewer: Current.user)
    others = people - [ viewer ]

    if others.any?
      button_to rooms_directs_path(user_ids: others.map(&:id)), class: "btn btn--reversed nearby__dm txt-small", form: { data: { turbo_frame: "_top" } } do
        image_tag("list-dms.svg", size: 18, aria: { hidden: "true" }) + tag.span(others.one? ? "DM #{others.first.name.split.first}" : "DM everyone here")
      end
    end
  end
end
