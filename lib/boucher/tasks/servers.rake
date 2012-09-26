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

  desc "Terminates the specified server"
  task :terminate, [:server_id] do |t, args|
    server = Boucher::Servers.with_id(args.server_id)

    if !server
      puts "Server #{args.server_id} does not exist"
      exit 1
    end

    begin
      Boucher::Servers.terminate(server)
    rescue => e
      puts "\nTermination failed. This may be due to termination protection. If
you're sure you wish to disable this protection, select the instance in the AWS
web console and click Instance Actions -> Change Termination Protection -> Yes."
      raise
    end
  end

  desc "Stops the specified server"
  task :stop, [:server_id] do |t, args|
    server = Boucher.compute.servers.get(args.server_id)
    Boucher::Servers.stop(args.server_id)
  end

  desc "Starts the specified server"
  task :start, [:server_id] do |t, args|
    Boucher::Servers.start(args.server_id)
    server = Boucher.compute.servers.get(args.server_id)
  end

  desc "Open an SSH session with the specified server"
  task :ssh, [:server_id] do |t, args|
    puts "Opening SSH session to #{args.server_id}"
    server = Boucher.compute.servers.get(args.server_id)
    Boucher.ssh server
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
    meal = Boucher.meal(args.meal)
    Boucher.provision(meal)
  end

  desc "Provision new, or chef existing server of the specified meal"
  task :establish, [:meal] do |t, args|
    server = Boucher.find_server(args.meal, ENV['BUTCHER_ENV'])
    Boucher.establish_server(server, args.meal)
  end

  desc "Cook the given meal on the given server"
  task :chef, [:meal, :server_id] do |t, args|
    server = Boucher.compute.servers.get(args.server_id)
    Boucher.cook_meal(server, args.meal)
  end
end

