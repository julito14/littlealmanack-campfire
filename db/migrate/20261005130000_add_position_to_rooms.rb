# The club's own order for its rooms in the sidebar, set by an administrator.
class AddPositionToRooms < ActiveRecord::Migration[8.2]
  def change
    add_column :rooms, :position, :integer
  end
end
