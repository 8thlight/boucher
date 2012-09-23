require 'json'
require 'fileutils'

def make_config_path(host_name)
  "/etc/nagios3/conf.d/#{host_name}.cfg"
end

def host_entry(host_name, ip)
<<-HOST
define host {
  host_name             #{host_name}
  alias                 #{host_name}
  address               #{ip}
  check_command         check_ssh
  notification_interval 0
  notification_period   24x7
  max_check_attempts    10
  notification_options  d,u,r
  notifications_enabled 1
}
HOST
end

def service_entry(host_name, ip, plugin)
<<-SERVICE
define command {
  command_name #{host_name}-#{plugin}
  command_line /usr/lib/nagios/plugins/check_nrpe -H #{ip} -c "#{plugin}"
}

define service {
  use                   generic-service
  host_name             #{host_name}
  check_command         #{host_name}-#{plugin}
  service_description   #{plugin}
  normal_check_interval 5
  check_period          24x7
  notifications_enabled 1
}
SERVICE
end

namespace :nagios do
  desc "Remove a nagios host from this machine"
  task :remove_host, [:name] do |t, args|
    FileUtils.rm_f make_config_path(args.name)
  end

  desc "Adds a nagios host to be monitored by this machine"
  task :add_host, [:name, :ip, :klass] do |t, args|
    checks = Butcher::Nagios.checks_for(args.klass)
    return if checks.empty?

    File.open(make_config_path(args.name), "w") do |file|
      host_name = "#{args.klass}-#{args.name}"

      file.puts host_entry(host_name, args.ip)

      checks.each do |plugin, command|
        file.puts
        file.puts service_entry(host_name, args.ip, plugin)
      end
    end
  end

  desc "Opens the nagios web console"
  task :open do
    server = Butcher::Servers["nagios_server"]
    url = "http://#{server.public_ip_address}/nagios3"
    puts "Nagios lives at #{url}"
    puts "Login using nagiosadmin / 'we are many lonely souls'"
    `open #{url}`
  end
end
