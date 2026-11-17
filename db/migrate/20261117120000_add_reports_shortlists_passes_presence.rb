class AddReportsShortlistsPassesPresence < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_seen_at, :datetime

    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reported_user, null: false, foreign_key: { to_table: :users }
      t.string :reason, null: false
      t.text :details
      t.string :status, null: false, default: "open"
      t.timestamps
    end
    add_index :reports, %i[reporter_id reported_user_id], unique: true

    create_table :shortlists do |t|
      t.references :user, null: false, foreign_key: true
      t.references :target_user, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :shortlists, %i[user_id target_user_id], unique: true

    create_table :profile_passes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :passed_user, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :profile_passes, %i[user_id passed_user_id], unique: true
  end
end
