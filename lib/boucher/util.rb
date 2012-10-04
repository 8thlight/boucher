module Boucher

  def self.current_user
    `git config user.name`.strip
  rescue
    "unknown"
  end

  def resolve_servers(id_or_meal)
    [Boucher::Servers.with_id(id_or_meal)]
  rescue
    puts "Searching for running #{id_or_meal} servers in #{Boucher.env_name} environment..."
    servers = Boucher::Servers.search(:meal => id_or_meal, :env => Boucher.env_name, :state => "!terminated")
    Boucher::print_servers[servers]
    servers
  end

end