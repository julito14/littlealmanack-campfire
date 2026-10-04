class CreateThreadParticipations < ActiveRecord::Migration[8.2]
  def change
    add_column :messages, :last_reply_at, :datetime

    create_table :thread_participations do |t|
      t.references :message, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :unread_at
      t.timestamps
    end
    add_index :thread_participations, %i[ message_id user_id ], unique: true

    # Threads that already have replies: their starters and repliers are in them, all caught up.
    up_only do
      execute <<~SQL
        UPDATE messages SET last_reply_at = (SELECT MAX(replies.created_at) FROM messages replies WHERE replies.parent_message_id = messages.id)
        WHERE replies_count > 0
      SQL
      execute <<~SQL
        INSERT OR IGNORE INTO thread_participations (message_id, user_id, created_at, updated_at)
        SELECT id, creator_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM messages WHERE replies_count > 0
        UNION
        SELECT parent_message_id, creator_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM messages WHERE parent_message_id IS NOT NULL
      SQL
    end
  end
end
