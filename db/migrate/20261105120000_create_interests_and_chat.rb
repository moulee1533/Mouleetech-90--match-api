class CreateInterestsAndChat < ActiveRecord::Migration[8.1]
  def change
    create_table :interests do |t|
      t.references :from_user, null: false, foreign_key: { to_table: :users }
      t.references :to_user, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.text :note
      t.timestamps
    end
    add_index :interests, %i[from_user_id to_user_id], unique: true
    add_index :interests, %i[to_user_id status]
    add_index :interests, %i[from_user_id status]

    create_table :conversations do |t|
      t.references :interest, null: false, foreign_key: true, index: { unique: true }
      t.datetime :last_message_at
      t.timestamps
    end

    create_table :conversation_participants do |t|
      t.references :conversation, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.datetime :last_read_at
      t.timestamps
    end
    add_index :conversation_participants, %i[conversation_id user_id], unique: true

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.timestamps
    end
    add_index :messages, %i[conversation_id created_at]
  end
end
