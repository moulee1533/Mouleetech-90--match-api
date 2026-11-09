class AddSignupFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :signup_step, :string, null: false, default: "basic"
    add_column :users, :profile_completed, :boolean, null: false, default: false
    add_index :users, :signup_step
    add_index :users, :profile_completed
  end
end
