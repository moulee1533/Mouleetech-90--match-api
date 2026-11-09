class CreateDigilockerSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :digilocker_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :state, null: false
      t.string :code_verifier
      t.string :status, null: false, default: "started"
      t.datetime :expires_at, null: false
      t.string :error_message

      t.timestamps
    end

    add_index :digilocker_sessions, :state, unique: true
    add_index :digilocker_sessions, :status
  end
end
