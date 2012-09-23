require 'butcher/env'
require 'butcher/classes'
require 'butcher/io'
require 'fog'
require 'retryable'

module Butcher

  EC2_CONFIG = {
          :provider => 'AWS',
          :aws_secret_access_key => Butcher::Config[:aws_secret_access_key],
          :aws_access_key_id => Butcher::Config[:aws_access_key_id],
          :region => Butcher::Config[:aws_region]
  }

  def self.compute
    @compute ||= Fog::Compute.new(EC2_CONFIG)
    @compute
  end

  def self.snapshots
    @snapshots ||= compute.snapshots
  end

  def self.ssh(server, command=nil)
    command_arg = nil
    if command
      command_arg = "\"#{command}\""
    end

    command = "#{ssh_command} #{Butcher::Config[:username]}@#{server.dns_name} #{command_arg}"
    verbose command
    Kernel.system command
    raise "command failed with code #{$?.exitstatus}" unless $?.success?
  end

  def self.ssh_command
    "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{Butcher::Config[:aws_key_filename]}.pem"
  end

  def self.download(server, remote_filepath, local_filepath)
    command = ["rsync", "-azb", "-e", ssh_command, "--delete-after", "#{Butcher::Config[:username]}@#{server.dns_name}:#{remote_filepath}", local_filepath]
    Kernel.system(*command)
    raise "command failed with code #{$?.exitstatus}: #{command.inspect}" unless $?.success?
  end

  def self.rsync(server, from, to)
    command = ["rsync", "-azb", "-e", ssh_command, "--delete-after",
      from, "#{Butcher::Config[:username]}@#{server.dns_name}:#{to}"]
    Kernel.system(*command)
    raise "command failed with code #{$?.exitstatus}: #{command.inspect}" unless $?.success?
  end

  def self.update_recipes(server)
    puts "Updating recipes on #{server.id}"
    ssh server, "cd infrastructure && git checkout . && git clean -d -f && git pull && bundle"

    %w[cookbooks config tasks].each do |folder|
      rsync server, "#{folder}/", "infrastructure/#{folder}/"
    end
  end

  def self.cook_meal(server, meal)
    Butcher::Nagios.remove_host(server)

    update_recipes(server)
    ssh server, "cd infrastructure && sudo BUTCHER_ENV=#{Butcher::Config[:env]} BRANCH=#{Butcher::Config[:branch]} chef-solo -c config/solo.rb -j config/#{meal}.json"

    Butcher::Nagios.add_host(server)
  end

  def self.ssh_open?(server)
    ssh server, "echo 'SSH is open for business!'"
    true
  rescue Exception => e
    false
  end

  def self.change_server_state(server_id, command, new_state)
    print "#{command}-ing server #{server_id}..."
    server = compute.servers.get(server_id)
    server.send(command.to_sym)
    server.wait_for { print "."; state == new_state }
    puts
    Butcher.print_servers [server]
    puts
    puts "The server has been #{command}-ed."
  end

  def self.find_servers
    compute.servers
  end
end
