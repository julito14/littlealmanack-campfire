require "zlib"

# The world's cities with 15,000+ people, from GeoNames (see script/data/build-cities), and each
# member's city. Members' free-text locations are matched to cities separately, with review
# (bin/rails cities:match_locations), since a wrong guess would put someone in the wrong place.
class CreateCities < ActiveRecord::Migration[8.2]
  class City < ActiveRecord::Base
    self.table_name = "cities"
  end

  def change
    create_table :cities do |t|
      t.string :name, null: false
      t.string :country_code, null: false
      t.string :country_name, null: false
      t.string :region
      t.text :alternate_names
      t.text :search_names, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.integer :population, null: false, default: 0
    end
    add_index :cities, :country_code

    add_reference :users, :city, index: true
    add_column :users, :country_code, :string

    up_only { load_cities }
  end

  private
    def load_cities
      Zlib::GzipReader.open(Rails.root.join("db/data/cities.tsv.gz")) do |file|
        file.each_line.map { |line| city_from(line) }.each_slice(1000) { |batch| City.insert_all(batch) }
      end
    end

    def city_from(line)
      id, name, ascii, aliases, country, country_name, region, latitude, longitude, population = line.chomp.split("\t")
      names = [ name, ascii, *aliases.to_s.split("|") ]

      { id: id.to_i, name: name, country_code: country, country_name: country_name, region: region.presence,
        alternate_names: aliases.presence, search_names: "|#{names.map { |n| I18n.transliterate(n).downcase }.uniq.join("|")}|",
        latitude: latitude.to_f, longitude: longitude.to_f, population: population.to_i }
    end
end
