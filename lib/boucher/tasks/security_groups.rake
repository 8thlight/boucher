require 'boucher/security_groups'
require 'pry'

namespace :security_groups do
  desc "List ALL AWS security groups"
  task :list do
    security_groups = Boucher::SecurityGroups.all
    servers_for_groups = Boucher::SecurityGroups.servers_for_groups
    Boucher::SecurityGroups::Printing.print_table(security_groups, servers_for_groups)
  end

  desc "Create security groups"
  task :build_all do
    security_group_file = File.open("config/security_groups.json", "r")
    security_groups = JSON.parse(security_group_file.read, symbolize_names: true)
    groups = security_groups[:groups]
    Boucher::SecurityGroups.build_for_configurations(groups)
  end
end

