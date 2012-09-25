require 'boucher/servers'
require 'boucher/compute'

module Boucher
  module Nagios
    def self.remove_host(host)
      return if host.tags["Class"] == "nagios_server"

      monitors_for(host.tags["Env"]).each do |monitor|
        commands = [
          "cd /home/#{Boucher::Config[:username]}/infrastructure",
          "sudo rake nagios:remove_host[#{host.id}]",
          "sudo /etc/init.d/nagios3 restart"
        ]
        Boucher.ssh(monitor, commands.join(" && "))
      end
    end

    def self.add_host(host)
      return if checks_for(host.tags["Class"]).empty?

      monitors_for(host.tags["Env"]).each do |monitor|
        commands = [
          "cd /home/#{Boucher::Config[:username]}/infrastructure",
          "sudo rake nagios:add_host[#{host.id},#{host.public_ip_address},#{host.tags["Class"]}]",
          "sudo /etc/init.d/nagios3 restart"
        ]

        Boucher.ssh(monitor, commands.join(" && "))
      end
    end

    def self.checks_for(server_class)
      config_path = File.expand_path("../../../config/#{server_class}.json", __FILE__)
      return [] unless File.exists? config_path
      server_configuration = JSON.parse(File.read config_path)
      server_configuration["nagios"] || []
    end

    private

    def self.monitors_for(env)
      Boucher::Servers.all.select do |monitor|
        monitor.tags["Class"] == "nagios_server" &&
        monitor.tags["Env"] == env &&
        monitor.dns_name
      end
    end
  end
end
