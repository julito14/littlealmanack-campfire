class CreateInvitations < ActiveRecord::Migration[8.2]
  def change
    create_table :invitations do |t|
      t.string :token, null: false
      t.string :email_address, null: false
      t.references :creator, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :user, foreign_key: { on_delete: :nullify }
      t.datetime :accepted_at
      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :email_address
  end
end
