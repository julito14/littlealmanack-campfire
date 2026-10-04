# A local chat ("📍 Mumbai area") is a closed room with the city it's around.
class AddCityToRooms < ActiveRecord::Migration[8.2]
  def change
    add_reference :rooms, :city, index: true
  end
end
