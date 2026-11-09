class CreateFamilyDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :family_details do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :family_type
      t.string :family_values
      t.string :family_status
      t.string :father_name
      t.string :father_occupation
      t.string :mother_name
      t.string :mother_occupation
      t.integer :brothers_count, null: false, default: 0
      t.integer :brothers_married, null: false, default: 0
      t.integer :sisters_count, null: false, default: 0
      t.integer :sisters_married, null: false, default: 0
      t.string :native_place
      t.text :about_family
      t.timestamps
    end
  end
end
