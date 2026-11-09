class CreatePartnerPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :partner_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :age_min
      t.integer :age_max
      t.integer :height_cm_min
      t.integer :height_cm_max
      t.jsonb :marital_statuses, null: false, default: []
      t.jsonb :religions, null: false, default: []
      t.jsonb :mother_tongues, null: false, default: []
      t.jsonb :castes, null: false, default: []
      t.jsonb :countries, null: false, default: []
      t.jsonb :states, null: false, default: []
      t.jsonb :cities, null: false, default: []
      t.jsonb :educations, null: false, default: []
      t.jsonb :occupations, null: false, default: []
      t.integer :income_min
      t.text :about_partner
      t.timestamps
    end
  end
end
