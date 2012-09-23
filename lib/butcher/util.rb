module Butcher

  def self.current_user
    `git config user.name`.strip
  rescue
    "unknown"
  end

end