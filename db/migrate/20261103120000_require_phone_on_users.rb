class RequirePhoneOnUsers < ActiveRecord::Migration[8.1]
  def up
    # Backfill missing phones so NOT NULL succeeds.
    execute <<~SQL.squish
      UPDATE users
      SET phone = CONCAT('+91000000', id)
      WHERE phone IS NULL OR TRIM(phone) = ''
    SQL

    change_column_null :users, :phone, false
  end

  def down
    change_column_null :users, :phone, true
  end
end
