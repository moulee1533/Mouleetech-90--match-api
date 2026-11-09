class CreateLocationDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :location_details do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :country
      t.string :state
      t.string :city
      t.string :citizenship
      t.string :residency_status
      t.boolean :willing_to_relocate
      t.timestamps
    end

    add_index :location_details, :city
    add_index :location_details, :state
  end
end
