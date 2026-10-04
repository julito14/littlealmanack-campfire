# Reads what a member typed in the old free-text location field ("Pune, india", "NYC, USA",
# "Fremont, CA", "São Paulo Brazil", "Netherlands") and finds their city, or just their country.
# Anything it can't read for sure is left for a person to check: a wrong guess would put
# someone in the wrong place.
class City::LocationMatch
  COUNTRY_ALIASES = { "usa" => "US", "us" => "US", "united states" => "US", "america" => "US",
    "uk" => "GB", "gb" => "GB", "united kingdom" => "GB", "england" => "GB", "great britain" => "GB", "uae" => "AE",
    "netherlands" => "NL", "holland" => "NL", "south korea" => "KR", "korea" => "KR", "czech republic" => "CZ",
    "turkey" => "TR", "ivory coast" => "CI" }

  US_STATES = { "al" => "Alabama", "ak" => "Alaska", "az" => "Arizona", "ar" => "Arkansas", "ca" => "California",
    "co" => "Colorado", "ct" => "Connecticut", "de" => "Delaware", "fl" => "Florida", "ga" => "Georgia", "hi" => "Hawaii",
    "id" => "Idaho", "il" => "Illinois", "in" => "Indiana", "ia" => "Iowa", "ks" => "Kansas", "ky" => "Kentucky",
    "la" => "Louisiana", "me" => "Maine", "md" => "Maryland", "ma" => "Massachusetts", "mi" => "Michigan",
    "mn" => "Minnesota", "ms" => "Mississippi", "mo" => "Missouri", "mt" => "Montana", "ne" => "Nebraska", "nv" => "Nevada",
    "nh" => "New Hampshire", "nj" => "New Jersey", "nm" => "New Mexico", "ny" => "New York", "nc" => "North Carolina",
    "nd" => "North Dakota", "oh" => "Ohio", "ok" => "Oklahoma", "or" => "Oregon", "pa" => "Pennsylvania", "ri" => "Rhode Island",
    "sc" => "South Carolina", "sd" => "South Dakota", "tn" => "Tennessee", "tx" => "Texas", "ut" => "Utah", "vt" => "Vermont",
    "va" => "Virginia", "wa" => "Washington", "wv" => "West Virginia", "wi" => "Wisconsin", "wy" => "Wyoming", "dc" => "District of Columbia" }

  attr_reader :text, :city, :country_code

  def initialize(text)
    @text = text.to_s.squish
    read
  end

  # :city (sure of the city), :country (only a country was given), or :unsure
  def outcome
    @outcome ||= if @unsure then :unsure elsif city then :city elsif country_code then :country else :unsure end
  end

  private
    def read
      parts = text.split(",").map(&:squish).compact_blank
      return @unsure = true if parts.empty?

      if parts.one? && (code = country_code_for(parts.first))
        @country_code = code
      else
        name, *hints = parts.one? ? split_trailing_country(parts.first) : parts
        find_city(name, hints)
      end
    end

    def find_city(name, hints)
      candidates = City.where("search_names LIKE ?", "%|#{City.sanitize_sql_like(City.normalize(name))}|%").order(population: :desc).to_a

      hints.each do |hint|
        in_region = candidates.select { |city| region_matches?(city, hint) }
        if in_region.any?
          candidates = in_region
        elsif (code = country_code_for(hint)) && candidates.any? { |city| city.country_code == code }
          candidates = candidates.select { |city| city.country_code == code }
        else
          @unsure = true # a hint we can't read, like "UL": better to ask than to guess
        end
      end

      @city = candidates.first
      @unsure ||= ambiguous?(candidates, hints)
    end

    # Two big cities with the same name and nothing to tell them apart (Valencia, Spain or Venezuela)
    def ambiguous?(candidates, hints)
      hints.empty? && candidates.second && candidates.second.population > candidates.first.population / 5
    end

    def region_matches?(city, hint)
      region = City.normalize(city.region)
      term = City.normalize(hint)
      region.present? && (region == term || (city.country_code == "US" && City.normalize(US_STATES[term]) == region))
    end

    # "São Paulo Brazil" → ["São Paulo", "Brazil"]
    def split_trailing_country(text)
      words = text.split
      [ 2, 1 ].each do |count|
        next unless words.size > count
        country = words.last(count).join(" ")
        return [ words[0...-count].join(" "), country ] if country_code_for(country)
      end
      [ text ]
    end

    def country_code_for(text)
      term = City.normalize(text)
      COUNTRY_ALIASES[term] || City.country_names.find { |_, name| City.normalize(name) == term }&.first
    end
end
