class AddOpenSignup < ActiveRecord::Migration[8.2]
  def change
    add_column :accounts, :open_signup, :boolean, default: false, null: false
    add_column :users, :joined_via, :string
  end
end
