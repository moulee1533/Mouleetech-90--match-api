class CreateMemberProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :member_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :gender
      t.date :date_of_birth
      t.integer :height_cm
      t.string :marital_status
      t.string :religion
      t.string :mother_tongue
      t.string :caste
      t.string :sub_caste
      t.string :community
      t.string :gothra
      t.string :dosham
      t.string :eating_habit
      t.string :drinking_habit
      t.string :smoking_habit
      t.text :about_me
      t.string :profile_created_for, default: "self", null: false
      t.timestamps
    end

    add_index :member_profiles, :gender
  end
end
