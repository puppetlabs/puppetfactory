Facter.add(:role) do
  setcode do
    case Process.uid
    when 0
      'instructor'
    else
      'student'
    end
  end
end
