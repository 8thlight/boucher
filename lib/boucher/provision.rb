require 'boucher/compute'
require 'boucher/io'
require 'boucher/servers'
require 'boucher/volumes'
require 'boucher/nagios'
require 'retryable'

module Boucher

  def self.get_server(meal, environment, state)
    begin
      Boucher::Servers.find(:env => environment.to_s, :meal => meal, :state => state)
    rescue Boucher::Servers::NotFound
      nil
    end
  end

  def self.find_server(meal, environment)
    get_server(meal, environment, "stopped") || get_server(meal, environment, "running")
  end

  def self.establish_all_servers
    Boucher.each_required_server do |server, meal|
      # Retries after 2, 4, 8, 16, 32, and 64 seconds
      retryable(:tries => 6, :sleep => lambda { |n| 2**n }) do
        # A RuntimeError will sometimes be thrown here, with a message of:
        # "command failed with code 255"
        Boucher.establish_server(server, meal)
      end
    end
  end

  def self.establish_server(server, meal)
    if server.nil?
      Boucher.provision(meal, Boucher.meals[meal.to_sym])
    elsif server.state == "stopped"
      Boucher::Servers.start(server.id)
      server.reload
      Boucher.cook_meals_on_server(meal, Boucher.meals[meal.to_sym], server)
    else
      Boucher.cook_meals_on_server(meal, Boucher.meals[meal.to_sym], server)
    end
  end

  def self.provision(meal, meal_map)
    puts "Provisioning new #{meal} server..."
    server = create_meal_server(meal_map)
    wait_for_server_to_boot(server)
    wait_for_server_to_accept_ssh(server)
    volumes = create_volumes(meal_map, server)
    attach_volumes(volumes, server)
    cook_meals_on_server(meal, meal_map, server)
    puts "\nThe new #{meal} server has been provisioned! id: #{server.id}"
  end

  def self.attach_elastic_ips(meal, server)
    puts "Attaching elastic IPs..."
    return unless Boucher::Config[:elastic_ips] && Boucher::Config[:elastic_ips][meal]

    puts "Associating #{server.id} with #{Boucher::Config[:elastic_ips][meal]}"
    compute.associate_address(server.id, Boucher::Config[:elastic_ips][meal])
  end

  private

  def self.cook_meals_on_server(meal, meal_map, server)
    return unless meal_map[:meals]

    meal_map[:meals].each do |meal|
      meal = meal.call if meal.is_a?(Proc)
      Boucher.cook_meal(server, meal)
    end

    attach_elastic_ips(meal, server)
  end

  def self.wait_for_server_to_accept_ssh(server)
    puts "Waiting for server's SSH port to open..."
    Fog.wait_for { ssh_open?(server) }
    puts
  end

  def self.wait_for_server_to_boot(server)
    print "Waiting for server to boot..."
    server.wait_for { print "."; server.ready? }
    puts
    Boucher.print_servers([server])
  end

  def self.create_meal_server(meal_map)
    server = compute.servers.new(:tags => {})
    Boucher.setup_meal(server, meal_map)
    server.save
    Boucher.print_servers([server])
    server
  end

  def self.create_volumes(meal_map, server)
    Array(meal_map[:volumes]).map do |volume_name|
      attributes = Boucher.volume_configs[volume_name]
      snapshot = snapshots.get(attributes[:snapshot])
      puts "Creating volume from snapshot #{snapshot.id}..."
      Boucher::Volumes.create(server.availability_zone, snapshot, attributes[:device])
    end
  end

  def self.attach_volumes(volumes, server)
    volumes.each do |volume|
      print "Attaching volume #{volume.id} to #{server.id}..."
      Boucher::Volumes.attach(volume, server)
      volume.wait_for { print "."; state == "in-use" }
      puts
    end
  end
end
