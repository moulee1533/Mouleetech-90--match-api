class CreateStaffUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_users do |t|
      t.string :username, null: false
      t.string :password_digest, null: false
      t.string :full_name, null: false
      t.string :role, null: false, default: "admin"
      t.boolean :active, null: false, default: true
      t.string :jti

      t.timestamps
    end

    add_index :staff_users, :username, unique: true
    add_index :staff_users, :jti, unique: true, where: "jti IS NOT NULL"
  end
end
