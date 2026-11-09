class StaffUserSerializer
  def self.call(staff)
    {
      id: staff.id,
      username: staff.username,
      full_name: staff.full_name,
      role: staff.role,
      active: staff.active
    }
  end
end
