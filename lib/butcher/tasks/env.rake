require 'butcher/env'
require 'butcher/provision'
require 'retryable'

namespace :env do

  desc "Attaches elastic IPs"
  task :elastic_ips, [:env] do |t, args|
    Butcher.force_env!(args.env)
    Butcher.each_required_server do |server, server_class|
      Butcher.attach_elastic_ips(server_class, server)
    end
  end

  desc "Starts and deploys all the servers for the specified environment"
  task :start, [:env] do |t, args|
    Butcher.force_env!(args.env)
    Butcher.assert_env!
    Butcher.establish_all_servers
  end

  desc "Stops all the servers for the specified environment"
  task :stop, [:env] do |t, args|
    Butcher.force_env!(args.env)

    Butcher.each_required_server do |server, server_class|
      if server
        Butcher::Servers.stop(server.id)
      else
        puts "No #{server_class} server found for #{Butcher::Config[:env]} environment."
      end
    end
  end

  desc "Terminates all servers for the specified environment"
  task :terminate, [:env] do |t, args|
    Butcher.force_env!(args.env)
    Butcher.each_required_server do |server, server_class|
      Butcher::Servers.terminate(server) if server
    end
  end
end
