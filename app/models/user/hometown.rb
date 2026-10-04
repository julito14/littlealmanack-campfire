# Where a member lives, as a city from the list. Their profile's location line and their country
# follow the city they pick; members from before the picker may have only a country, or old text.
module User::Hometown
  extend ActiveSupport::Concern

  included do
    belongs_to :city, optional: true
    before_save :follow_city, if: :city_id_changed?
  end

  def country_name
    city&.country_name || City.country_names[country_code]
  end

  private
    def follow_city
      self.location = city&.label
      self.country_code = city&.country_code
    end
end
