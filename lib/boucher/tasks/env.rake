require 'boucher/env'
require 'boucher/provision'
require 'retryable'

namespace :env do

  #desc "Attaches elastic IPs"
  #task :elastic_ips, [:env] do |t, args|
  #  Boucher.force_env!(args.env)
  #  Boucher.each_required_server do |server, meal|
  #    Boucher.attach_elastic_ips(meal, server)
  #  end
  #end

  desc "Starts and deploys all the servers for the specified environment"
  task :start, [:env] do |t, args|
    Boucher.force_env!(args.env)
    Boucher.assert_env!
    Boucher.establish_all_servers
  end

  desc "Stops all the servers for the specified environment"
  task :stop, [:env] do |t, args|
    Boucher.force_env!(args.env)

    Boucher.each_required_server do |server, meal|
      if server
        Boucher::Servers.stop(server.id)
      else
        puts "No #{meal} server found for #{Boucher::Config[:env]} environment."
      end
    end
  end

  desc "Terminates all servers for the specified environment"
  task :terminate, [:env] do |t, args|
    Boucher.force_env!(args.env)
    Boucher.each_required_server do |server, meal|
      Boucher::Servers.terminate(server) if server
    end
  end
end
