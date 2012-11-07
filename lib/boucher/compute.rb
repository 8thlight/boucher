require 'boucher/env'
require 'boucher/meals'
require 'boucher/io'
require 'fog'
require 'retryable'

module Boucher

  EC2_CONFIG = {
          :provider => 'AWS',
          :aws_secret_access_key => Boucher::Config[:aws_secret_access_key],
          :aws_access_key_id => Boucher::Config[:aws_access_key_id],
          :region => Boucher::Config[:aws_region]
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

    command = "#{ssh_command} #{Boucher::Config[:username]}@#{server.dns_name} #{command_arg}"
    verbose command
    Kernel.system command
    raise "command failed with code #{$?.exitstatus}" unless $?.success?
  end

  def self.ssh_command
    "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{Boucher::Config[:aws_key_filename]}.pem"
  end

  def self.update_recipes(server)
    puts "Updating recipes on #{server.id}"
    ssh server, "cd infrastructure && git checkout . && git clean -d -f && git pull && bundle"
  end

  def self.cook_meal(server, meal_name)
    update_recipes(server)
    ssh server, "cd infrastructure && sudo BENV=#{Boucher::Config[:env]} BRANCH=#{Boucher::Config[:branch]} chef-solo -c config/solo.rb -j config/#{meal_name}.json"
  end

  def self.cook_recipe(server, recipe)
    update_recipes(server)
    ssh server, "echo '{\\\"run_list\\\": [\\\"recipe[#{recipe}]\\\"]}' > /tmp/single_recipe.json"
    ssh server, "cd infrastructure && sudo BENV=#{Boucher::Config[:env]} BRANCH=#{Boucher::Config[:branch]} chef-solo -c config/solo.rb -j /tmp/single_recipe.json"
  end

  def self.ssh_open?(server)
    ssh server, "echo 'SSH is open for business!'"
    true
  rescue Exception => e
    false
  end
end
