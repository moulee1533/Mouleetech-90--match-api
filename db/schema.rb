# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_05_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "career_details", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "highest_education"
    t.string "education_detail"
    t.string "college_name"
    t.string "employed_in"
    t.string "occupation"
    t.string "organization_name"
    t.integer "annual_income_min"
    t.integer "annual_income_max"
    t.string "income_currency", default: "INR", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_career_details_on_user_id", unique: true
  end

  create_table "conversation_participants", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "user_id", null: false
    t.datetime "last_read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "user_id"], name: "index_conversation_participants_on_conversation_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_conversation_participants_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "interest_id", null: false
    t.datetime "last_message_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interest_id"], name: "index_conversations_on_interest_id", unique: true
  end

  create_table "digilocker_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "state", null: false
    t.string "code_verifier"
    t.string "status", default: "started", null: false
    t.datetime "expires_at", null: false
    t.string "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state"], name: "index_digilocker_sessions_on_state", unique: true
    t.index ["status"], name: "index_digilocker_sessions_on_status"
    t.index ["user_id"], name: "index_digilocker_sessions_on_user_id"
  end

  create_table "family_details", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "family_type"
    t.string "family_values"
    t.string "family_status"
    t.string "father_name"
    t.string "father_occupation"
    t.string "mother_name"
    t.string "mother_occupation"
    t.integer "brothers_count", default: 0, null: false
    t.integer "brothers_married", default: 0, null: false
    t.integer "sisters_count", default: 0, null: false
    t.integer "sisters_married", default: 0, null: false
    t.string "native_place"
    t.text "about_family"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_family_details_on_user_id", unique: true
  end

  create_table "interests", force: :cascade do |t|
    t.bigint "from_user_id", null: false
    t.bigint "to_user_id", null: false
    t.string "status", default: "pending", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_user_id", "status"], name: "index_interests_on_from_user_id_and_status"
    t.index ["from_user_id", "to_user_id"], name: "index_interests_on_from_user_id_and_to_user_id", unique: true
    t.index ["from_user_id"], name: "index_interests_on_from_user_id"
    t.index ["to_user_id", "status"], name: "index_interests_on_to_user_id_and_status"
    t.index ["to_user_id"], name: "index_interests_on_to_user_id"
  end

  create_table "location_details", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "country"
    t.string "state"
    t.string "city"
    t.string "citizenship"
    t.string "residency_status"
    t.boolean "willing_to_relocate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_location_details_on_city"
    t.index ["state"], name: "index_location_details_on_state"
    t.index ["user_id"], name: "index_location_details_on_user_id", unique: true
  end

  create_table "member_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "gender"
    t.date "date_of_birth"
    t.integer "height_cm"
    t.string "marital_status"
    t.string "religion"
    t.string "mother_tongue"
    t.string "caste"
    t.string "sub_caste"
    t.string "community"
    t.string "gothra"
    t.string "dosham"
    t.string "eating_habit"
    t.string "drinking_habit"
    t.string "smoking_habit"
    t.text "about_me"
    t.string "profile_created_for", default: "self", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gender"], name: "index_member_profiles_on_gender"
    t.index ["user_id"], name: "index_member_profiles_on_user_id", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "sender_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "partner_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "age_min"
    t.integer "age_max"
    t.integer "height_cm_min"
    t.integer "height_cm_max"
    t.jsonb "marital_statuses", default: [], null: false
    t.jsonb "religions", default: [], null: false
    t.jsonb "mother_tongues", default: [], null: false
    t.jsonb "castes", default: [], null: false
    t.jsonb "countries", default: [], null: false
    t.jsonb "states", default: [], null: false
    t.jsonb "cities", default: [], null: false
    t.jsonb "educations", default: [], null: false
    t.jsonb "occupations", default: [], null: false
    t.integer "income_min"
    t.text "about_partner"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_partner_preferences_on_user_id", unique: true
  end

  create_table "staff_users", force: :cascade do |t|
    t.string "username", null: false
    t.string "password_digest", null: false
    t.string "full_name", null: false
    t.string "role", default: "admin", null: false
    t.boolean "active", default: true, null: false
    t.string "jti"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_staff_users_on_jti", unique: true, where: "(jti IS NOT NULL)"
    t.index ["username"], name: "index_staff_users_on_username", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "full_name", null: false
    t.string "phone", null: false
    t.string "digilocker_id"
    t.string "digilocker_subject"
    t.datetime "digilocker_verified_at"
    t.jsonb "digilocker_raw_profile", default: {}, null: false
    t.string "status", default: "pending_verification", null: false
    t.string "jti"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "signup_step", default: "basic", null: false
    t.boolean "profile_completed", default: false, null: false
    t.index ["digilocker_id"], name: "index_users_on_digilocker_id", unique: true, where: "(digilocker_id IS NOT NULL)"
    t.index ["digilocker_subject"], name: "index_users_on_digilocker_subject", unique: true, where: "(digilocker_subject IS NOT NULL)"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true, where: "(jti IS NOT NULL)"
    t.index ["phone"], name: "index_users_on_phone", unique: true, where: "(phone IS NOT NULL)"
    t.index ["profile_completed"], name: "index_users_on_profile_completed"
    t.index ["signup_step"], name: "index_users_on_signup_step"
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "career_details", "users"
  add_foreign_key "conversation_participants", "conversations"
  add_foreign_key "conversation_participants", "users"
  add_foreign_key "conversations", "interests"
  add_foreign_key "digilocker_sessions", "users"
  add_foreign_key "family_details", "users"
  add_foreign_key "interests", "users", column: "from_user_id"
  add_foreign_key "interests", "users", column: "to_user_id"
  add_foreign_key "location_details", "users"
  add_foreign_key "member_profiles", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "partner_preferences", "users"
end
