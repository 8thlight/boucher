require 'boucher/security_groups'

namespace :security_groups do
  desc "List ALL AWS security groups"
  task :list do
    security_groups = Boucher::SecurityGroups.all
    servers_for_groups = Boucher::SecurityGroups.servers_for_groups
    Boucher::SecurityGroups::Printing.print_table(security_groups, servers_for_groups)
  end

  desc "Associate servers and security groups"
  task :associate do
    security_group_file = File.open("config/security_groups.json", "r")
    security_groups = JSON.parse(security_group_file.read)
    mapping = security_groups["mapping"]
    Boucher::SecurityGroups.associate_servers(mapping)
  end
end

