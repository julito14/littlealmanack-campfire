class AddClosedSignupUrlToAccounts < ActiveRecord::Migration[8.2]
  def change
    add_column :accounts, :closed_signup_url, :string
  end
end
