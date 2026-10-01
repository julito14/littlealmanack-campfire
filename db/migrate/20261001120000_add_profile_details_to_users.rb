class AddProfileDetailsToUsers < ActiveRecord::Migration[8.2]
  def change
    add_column :users, :location, :string
    add_column :users, :books, :text
    add_column :users, :website_url, :string
    add_column :users, :x_handle, :string
    add_column :users, :linkedin_url, :string
    add_column :users, :instagram_handle, :string
  end
end
