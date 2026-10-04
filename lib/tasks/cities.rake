namespace :cities do
  desc "Match members' old free-text locations to cities. Shows what it would do; APPLY=1 saves the sure ones"
  task match_locations: :environment do
    apply = ENV["APPLY"] == "1"
    members = User.active.without_bots.where(city_id: nil).where.not(location: [ nil, "" ])

    members.find_each do |member|
      match = City::LocationMatch.new(member.location)
      proposal = match.city&.then { "#{it.name}, #{it.place}" } || (match.country_code && "country #{City.country_names[match.country_code]}")

      puts [ member.id.to_s.rjust(4), match.outcome.to_s.ljust(7), member.location.ljust(28), "→ #{proposal || "?"}" ].join("  ")

      if apply
        case match.outcome
        when :city    then member.update!(city: match.city)
        when :country then member.update_columns(country_code: match.country_code)
        end
      end
    end

    puts apply ? "Saved the city and country matches; unsure ones are untouched." : "Dry run: nothing saved. APPLY=1 saves the city and country matches."
  end
end
