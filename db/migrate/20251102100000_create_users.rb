class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :full_name, null: false
      t.string :phone
      t.string :digilocker_id
      t.string :digilocker_subject
      t.datetime :digilocker_verified_at
      t.jsonb :digilocker_raw_profile, null: false, default: {}
      t.string :status, null: false, default: "pending_verification"
      t.string :jti

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :phone, unique: true, where: "phone IS NOT NULL"
    add_index :users, :digilocker_id, unique: true, where: "digilocker_id IS NOT NULL"
    add_index :users, :digilocker_subject, unique: true, where: "digilocker_subject IS NOT NULL"
    add_index :users, :status
    add_index :users, :jti, unique: true, where: "jti IS NOT NULL"
  end
end
