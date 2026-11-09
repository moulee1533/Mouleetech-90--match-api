class CreateCareerDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :career_details do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :highest_education
      t.string :education_detail
      t.string :college_name
      t.string :employed_in
      t.string :occupation
      t.string :organization_name
      t.integer :annual_income_min
      t.integer :annual_income_max
      t.string :income_currency, null: false, default: "INR"
      t.timestamps
    end
  end
end
