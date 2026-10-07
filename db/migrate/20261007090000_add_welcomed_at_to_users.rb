# When a member saw the welcome note, shown once on their first visit. Everyone already in the
# community counts as welcomed, so only people joining from now on see it.
class AddWelcomedAtToUsers < ActiveRecord::Migration[8.2]
  def change
    add_column :users, :welcomed_at, :datetime
    up_only { execute "UPDATE users SET welcomed_at = CURRENT_TIMESTAMP" }
  end
end
