class AddThreadsToMessages < ActiveRecord::Migration[8.2]
  def change
    add_reference :messages, :parent_message, index: true
    add_column :messages, :replies_count, :integer, default: 0, null: false
  end
end
