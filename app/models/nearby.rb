# Where members are, for the Nearby view of Members and the city and country pages: who's within
# 50 km of a city, and every country with its areas. An area is a members' city plus their other
# cities within 50 km of it, named after the biggest, so "Mumbai area" takes in Ulhasnagar.
class Nearby
  RADIUS_KM = 50

  Area = Data.define(:city, :members) do
    def size = members.size

    def label
      members.map(&:city_id).uniq.many? ? "#{city.name} area" : city.name
    end
  end

  Country = Data.define(:code, :name, :areas, :members_without_city) do
    def size = areas.sum(&:size) + members_without_city.size
  end

  def initialize(members = User.active.without_bots.includes(:city))
    @members = members.to_a
  end

  # Members within 50 km of the city, nearest first, as [member, km] pairs.
  def around(city)
    return [] unless city

    @members.select(&:city).map { |member| [ member, member.city.distance_to(city) ] }
      .select { |_, km| km <= RADIUS_KM }.sort_by { |member, km| [ km.round, member.name.downcase ] }
  end

  def countries
    @countries ||= @members.select { |member| member.city || member.country_code }
      .group_by { |member| member.city&.country_code || member.country_code }
      .map { |code, members| country_from(code, members) }
      .sort_by { |country| [ -country.size, country.name ] }
  end

  def country(code)
    countries.find { |country| country.code == code }
  end

  private
    def country_from(code, members)
      with_city, without_city = members.partition(&:city)
      Country.new(code: code, name: City.country_names[code] || code, areas: areas_from(with_city), members_without_city: without_city)
    end

    # Biggest city first: it gathers every members' city within 50 km that isn't taken yet.
    def areas_from(members)
      by_city = members.group_by(&:city)

      by_city.keys.sort_by { |city| -city.population }.filter_map do |anchor|
        next unless by_city.key?(anchor)

        nearby = by_city.keys.select { |city| city.distance_to(anchor) <= RADIUS_KM }
        Area.new(city: anchor, members: nearby.flat_map { |city| by_city.delete(city) })
      end.sort_by { |area| [ -area.size, area.city.name ] }
    end
end
