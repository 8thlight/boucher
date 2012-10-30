require 'boucher/security_groups'
#require 'boucher/compute'
#require 'boucher/env'
#require 'boucher/io'
#require 'boucher/meals'
#require 'boucher/provision'
#require 'boucher/servers'
#require 'boucher/volumes'
#require 'retryable'
#
#def meals
#  config_files = Dir.glob("config/*.json")
#  configs = config_files.map { |config_file| File.basename(config_file) }
#  configs.map { |config| config.gsub(".json", "") }
#end
#
#def server_listing(description, servers)
#  puts "Listing all AWS server #{description}..."
#  Boucher.print_servers servers
#  puts
#  puts "#{servers.size} server(s)"
#end
#
namespace :security_groups do
  desc "List ALL AWS security groups"
  task :list do
    security_groups = Boucher::SecurityGroups.all
    Boucher::SecurityGroups::Printing.print_table(security_groups)
  end
end

