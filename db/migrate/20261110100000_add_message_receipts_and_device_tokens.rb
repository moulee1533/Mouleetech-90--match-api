class AddMessageReceiptsAndDeviceTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :delivered_at, :datetime
    add_column :messages, :read_at, :datetime

    create_table :device_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.string :platform, null: false, default: "android"
      t.timestamps
    end

    add_index :device_tokens, :token, unique: true
    add_index :device_tokens, %i[user_id platform]
  end
end
