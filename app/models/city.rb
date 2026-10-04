# A city members can say they live in, from GeoNames' list of cities with 15,000+ people
# (CC BY 4.0, https://www.geonames.org). Searching by alternate names is what makes "NYC"
# find New York City and "Bangalore" find Bengaluru.
class City < ApplicationRecord
  EARTH_RADIUS_KM = 6371

  has_many :users, dependent: :nullify

  class << self
    def search(query, limit: 8)
      term = normalize(query)
      return none if term.length < 2

      where("search_names LIKE ?", "%|#{sanitize_sql_like(term)}%").order(population: :desc).limit(limit)
    end

    # The best match for a typed name, preferring the given country and then the biggest city.
    def named(name, country_code: nil)
      term = normalize(name)
      matches = where("search_names LIKE ?", "%|#{sanitize_sql_like(term)}|%")
      matches = matches.where(country_code: country_code) if country_code
      matches.order(population: :desc).first
    end

    def country_names
      @country_names ||= distinct.pluck(:country_code, :country_name).to_h
    end

    def normalize(text)
      I18n.transliterate(text.to_s).downcase.squish
    end
  end

  def label
    "#{name}, #{country_name}"
  end

  # Where it is, to tell apart cities with the same name: "California, United States".
  def place
    [ region, country_name ].compact_blank.uniq.join(", ")
  end

  # When someone typed another name in full ("Bangalore" for Bengaluru, "NYC"), that name, to show
  # why this city came up. Partial matches aren't shown: they can land on an odd spelling.
  def alias_matching(query)
    term = self.class.normalize(query)
    return if self.class.normalize(name).start_with?(term)

    alternate_names.to_s.split("|").find { |alias_name| self.class.normalize(alias_name) == term }
  end

  def distance_to(other)
    lat1, lat2 = latitude * Math::PI / 180, other.latitude * Math::PI / 180
    dlat, dlng = lat2 - lat1, (other.longitude - longitude) * Math::PI / 180

    a = Math.sin(dlat / 2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dlng / 2)**2
    2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(a))
  end
end
