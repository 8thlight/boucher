require 'boucher/compute'
require 'boucher/env'
require 'boucher/io'
require 'boucher/meals'
require 'boucher/provision'
require 'boucher/servers'
require 'boucher/volumes'
require 'retryable'

def meals
  config_files = Dir.glob("config/*.json")
  configs = config_files.map { |config_file| File.basename(config_file) }
  configs.map { |config| config.gsub(".json", "") }
end

def server_listing(description, servers)
  puts "Listing all AWS server #{description}..."
  Boucher.print_servers servers
  puts
  puts "#{servers.size} server(s)"
end

namespace :servers do
  desc "List all volumes for a given server"
  task :volumes, [:server_id] do |t, args|
    volumes = Boucher::Servers.with_id(args.server_id).volumes
    Boucher.print_volumes(volumes)
  end

  desc "List ALL AWS servers, with optional [env] param."
  task :list, [:env] do |t, args|
    servers = Boucher::Servers.all
    servers = args.env ? servers.in_env(args.env) : servers
    server_listing("", servers)
  end

  desc "List AWS servers in specified environment"
  task :in_env, [:env] do |t, args|
    server_listing("in the '#{args.env}' environment", Boucher::Servers.in_env(args.env))
  end

  desc "List AWS servers of the specified meal"
  task :of_meal, [:meal] do |t, args|
    server_listing("of meal '#{args.meal}'", Boucher::Servers.of_meal(args.meal))
  end

  desc "Terminates the specified server(s)"
  task :terminate, [:id_or_meal] do |t, args|
    servers = Boucher.resolve_servers(args.id_or_meal)

    begin
      Boucher::Servers.terminate(servers) if !servers.empty?
    rescue => e
      puts "\nTermination failed. This may be due to termination protection. If
you're sure you wish to disable this protection, select the instance in the AWS
web console and click Instance Actions -> Change Termination Protection -> Yes."
      raise
    end
  end

  desc "Stops the specified server(s)"
  task :stop, [:id_or_meal] do |t, args|
    servers = Boucher.resolve_servers(args.id_or_meal)
    Boucher::Servers.stop(servers) if !servers.empty?
  end

  desc "Starts the specified server(s)"
  task :start, [:id_or_meal] do |t, args|
    servers = Boucher.resolve_servers(args.id_or_meal)
    Boucher::Servers.start(servers) if !servers.empty?
  end

  desc "Restarts the specified server(s)"
  task :restart, [:id_or_meal] do |t, args|
    servers = Boucher.resolve_servers(args.id_or_meal)
    Boucher::Servers.restart(servers) if !servers.empty?
  end

  desc "Open an SSH session with the specified server"
  task :ssh, [:id_or_meal, :command] do |t, args|
    server_id = Boucher.resolve_servers(args.id_or_meal).first.id
    args.with_defaults(:command => nil)
    server = Boucher.compute.servers.get(server_id)
    Boucher.ssh server, args.command
  end

  desc "Download a file from the server"
  task :download, [:server_id, :filepath] do |t, args|
    server = Boucher.compute.servers.get(args.server_id)
    remote_path = args.filepath
    local_path = File.expand_path(File.join("..", "..", File.basename(args.filepath)), __FILE__)

    Boucher.download(server, remote_path, local_path)
  end

  desc "Fix permissions on key files"
  task :key_fix do
    system "chmod 0600 *.pem"
  end

  desc "Provision new server [#{Boucher.meals.keys.sort.join(', ')}]"
  task :provision, [:meal] do |t, args|
    Boucher.assert_env!
    meal = Boucher.meal(args.meal)
    Boucher.provision(meal)
  end

  desc "Provision new, or chef existing server of the specified meal"
  task :establish, [:meal] do |t, args|
    Boucher.assert_env!
    server = Boucher.find_server(args.meal, ENV['BENV'])
    Boucher.establish_server(server, args.meal)
  end

  desc "Cook the specified meal on the instance(s) specified by the given id or meal"
  task :meal, [:meal, :server_id] do |t, args|
    Boucher.assert_env!
    servers = Boucher.resolve_servers(args.server_id || args.meal)
    servers.each do |server|
      Boucher.cook_meal(server, args.meal)
    end
  end

  desc "Cook the specified recipe on the instance(s) specified by the given id or meal"
  task :recipe, [:recipe, :id_or_meal] do |t, args|
    servers = Boucher.resolve_servers(args.id_or_meal || args.meal)
    servers.each do |server|
      Boucher.cook_recipe(server, args.recipe)
    end
  end
end

