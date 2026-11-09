# Local-only seed users (passwords documented in README).

# Free reserved DigiLocker ids so re-seed does not collide with older rows.
User.where(digilocker_id: "seed-admin-digilocker")
    .or(User.where(digilocker_subject: "seed-admin-digilocker"))
    .where.not(phone: "9999999999")
    .update_all(digilocker_id: nil, digilocker_subject: nil, digilocker_verified_at: nil)

admin = User.find_or_initialize_by(phone: "9999999999")
admin.assign_attributes(
  email: "9999999999@phone.ninetiesmatch.local",
  full_name: "Local Admin",
  password: "Password1",
  password_confirmation: "Password1",
  status: "active",
  signup_step: "done",
  profile_completed: true,
  digilocker_id: "seed-admin-digilocker",
  digilocker_subject: "seed-admin-digilocker",
  digilocker_verified_at: Time.current,
  digilocker_raw_profile: {
    "sub" => "seed-admin-digilocker",
    "name" => "Local Admin",
    "mode" => "hardcoded_temp"
  }
)
admin.save!

admin.create_member_profile!(
  gender: "male",
  date_of_birth: Date.new(1992, 5, 15),
  height_cm: 175,
  marital_status: "never_married",
  religion: "Hindu",
  mother_tongue: "Tamil",
  caste: "Other",
  community: "Tamil",
  profile_created_for: "self",
  about_me: "Seeded complete profile for local testing."
) unless admin.member_profile

admin.create_family_detail!(
  family_type: "nuclear",
  family_values: "moderate",
  family_status: "middle_class",
  native_place: "Chennai"
) unless admin.family_detail

admin.create_career_detail!(
  highest_education: "Bachelors",
  employed_in: "private",
  occupation: "Software Engineer",
  organization_name: "Greenbotz",
  annual_income_min: 800_000,
  annual_income_max: 1_200_000
) unless admin.career_detail

admin.create_location_detail!(
  country: "India",
  state: "Tamil Nadu",
  city: "Chennai",
  citizenship: "India",
  residency_status: "citizen",
  willing_to_relocate: true
) unless admin.location_detail

admin.create_partner_preference!(
  age_min: 24,
  age_max: 32,
  height_cm_min: 150,
  height_cm_max: 170,
  marital_statuses: [ "never_married" ],
  religions: [ "Hindu" ],
  mother_tongues: [ "Tamil" ],
  countries: [ "India" ],
  states: [ "Tamil Nadu" ]
) unless admin.partner_preference

pending = User.find_or_initialize_by(phone: "8888888888")
pending.assign_attributes(
  email: "8888888888@phone.ninetiesmatch.local",
  full_name: "Pending User",
  password: "Password1",
  password_confirmation: "Password1",
  status: "pending_verification",
  signup_step: "basic",
  profile_completed: false
)
pending.save!

staff = StaffUser.find_or_initialize_by(username: "admin")
staff.assign_attributes(
  full_name: "Staff Admin",
  password: "Password1",
  password_confirmation: "Password1",
  role: "admin",
  active: true
)
staff.save!

puts "Seeded member users (phone / password):"
puts "  9999999999 / Password1 (active + full profile)"
puts "  8888888888 / Password1 (pending — needs profile + DigiLocker)"
puts "Seeded staff:"
puts "  username: admin / password: Password1 (admin panel)"
puts "Temp DigiLocker OTP: 123456"

# --- 100 demo profiles for list / card UI testing (no photos) ---
CITIES = %w[Chennai Coimbatore Madurai Trichy Salem Erode Tirunelveli Vellore].freeze
RELIGIONS = %w[Hindu Christian Muslim].freeze
TONGUES = %w[Tamil Telugu Malayalam Kannada].freeze
OCCUPATIONS = [ "Software Engineer", "Doctor", "Teacher", "Accountant", "Business", "Banker", "Designer", "Nurse" ].freeze
EDUCATIONS = %w[Bachelors Masters Diploma].freeze
FIRST_NAMES_F = %w[Ananya Divya Kavya Meera Priya Sneha Lakshmi Nisha Swathi Deepa Ishwari Keerthi].freeze
FIRST_NAMES_M = %w[Arun Karthik Vishnu Suresh Ramesh Ajay Pranav Hari Kishore Manoj Sathish Vivek].freeze
LAST_NAMES = %w[Kumar Krishnan Iyer Reddy Nair Pillai Das Gupta Rao Srinivasan].freeze

created_demo = 0
(1..100).each do |i|
  phone = format("900%07d", i) # 9000000001 … 9000000100
  female = i.odd?
  first = female ? FIRST_NAMES_F[i % FIRST_NAMES_F.size] : FIRST_NAMES_M[i % FIRST_NAMES_M.size]
  last = LAST_NAMES[i % LAST_NAMES.size]
  full_name = "#{first} #{last}"
  age = 24 + (i % 16)
  dob = Date.new(Time.zone.today.year - age, ((i % 12) + 1), ((i % 27) + 1))

  user = User.find_or_initialize_by(phone: phone)
  user.assign_attributes(
    email: "#{phone}@phone.ninetiesmatch.local",
    full_name: full_name,
    password: "Password1",
    password_confirmation: "Password1",
    status: "active",
    signup_step: "done",
    profile_completed: true
  )
  # Skip DigiLocker uniqueness — leave unverified for most; verify every 10th.
  if i % 10 == 0
    user.digilocker_id = "seed-demo-#{phone}"
    user.digilocker_subject = "seed-demo-#{phone}"
    user.digilocker_verified_at = Time.current
  else
    user.digilocker_id = nil
    user.digilocker_subject = nil
    user.digilocker_verified_at = nil
  end
  user.save!
  created_demo += 1 if user.previously_new_record? || user.saved_change_to_full_name?

  unless user.member_profile
    user.create_member_profile!(
      gender: female ? "female" : "male",
      date_of_birth: dob,
      height_cm: female ? (150 + (i % 20)) : (165 + (i % 25)),
      marital_status: "never_married",
      religion: RELIGIONS[i % RELIGIONS.size],
      mother_tongue: TONGUES[i % TONGUES.size],
      caste: "Other",
      community: "Tamil",
      profile_created_for: "self",
      about_me: "Demo profile ##{i} for layout testing."
    )
  end

  unless user.location_detail
    user.create_location_detail!(
      country: "India",
      state: "Tamil Nadu",
      city: CITIES[(i - 1) % CITIES.size],
      citizenship: "India",
      residency_status: "citizen",
      willing_to_relocate: i.even?
    )
  end

  unless user.career_detail
    user.create_career_detail!(
      highest_education: EDUCATIONS[i % EDUCATIONS.size],
      employed_in: "private",
      occupation: OCCUPATIONS[i % OCCUPATIONS.size],
      organization_name: "Demo Org",
      annual_income_min: 400_000 + (i * 10_000),
      annual_income_max: 600_000 + (i * 10_000)
    )
  end

  unless user.family_detail
    user.create_family_detail!(
      family_type: "nuclear",
      family_values: "moderate",
      family_status: "middle_class",
      native_place: CITIES[i % CITIES.size]
    )
  end

  unless user.partner_preference
    user.create_partner_preference!(
      age_min: 22,
      age_max: 35,
      marital_statuses: [ "never_married" ],
      religions: [ RELIGIONS[i % RELIGIONS.size] ],
      mother_tongues: [ "Tamil" ],
      countries: [ "India" ],
      states: [ "Tamil Nadu" ]
    )
  end
end

puts "Demo directory profiles: 100 (phones 9000000001–9000000100 / Password1)"
puts "  upserted this run marker count: #{created_demo}"

# Gender-matched anime portraits for first 20 demo phones (odd=female, even=male).
# Each profile gets 3 photos: pNNN_1 (avatar) + pNNN_2 + pNNN_3 under db/seed_images/profiles/.
attached = 0
(1..20).each do |i|
  phone = format("900%07d", i)
  user = User.find_by(phone: phone)
  next unless user

  folder = Rails.root.join("db/seed_images/profiles")
  pad = format("%03d", i)
  paths = [
    folder.join("p#{pad}_1.jpg"),
    folder.join("p#{pad}_2.jpg"),
    folder.join("p#{pad}_3.jpg")
  ]
  next unless paths.all?(&:exist?)

  expected_female = i.odd?
  gender = user.member_profile&.gender
  if expected_female && gender != "female"
    warn "Gender mismatch skip #{phone} (expected female)"
    next
  end
  if !expected_female && gender != "male"
    warn "Gender mismatch skip #{phone} (expected male)"
    next
  end

  user.avatar.purge if user.avatar.attached?
  user.photos.purge if user.photos.attached?

  files = paths.map do |path|
    content_type = path.extname == ".png" ? "image/png" : "image/jpeg"
    { io: File.open(path), filename: path.basename.to_s, content_type: content_type }
  end
  user.photos.attach(files)
  user.avatar.attach(user.photos.first.blob)
  attached += 1
end

puts "Attached seed portraits: #{attached}/20 profiles (3 photos each)"
