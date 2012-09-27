require 'boucher/compute'
require 'boucher/io'
require 'boucher/servers'
require 'boucher/volumes'
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

  def self.establish_server(server, meal_name)
    meal = Boucher.meal(meal_name)
    if server.nil?
      Boucher.provision(meal)
    elsif server.state == "stopped"
      Boucher::Servers.start(server.id)
      server.reload
      Boucher.cook_meal_on_server(meal, server)
    else
      Boucher.cook_meal_on_server(meal, server)
    end
  end

  def self.provision(meal)
    puts "Provisioning new #{meal[:name]} server..."
    server = create_meal_server(meal)
    wait_for_server_to_boot(server)
    wait_for_server_to_accept_ssh(server)
    volumes = create_volumes(meal, server)
    attach_volumes(volumes, server)
    cook_meal_on_server(meal, server)
    puts "\nThe new #{meal[:name]} server has been provisioned! id: #{server.id}"
  end

  def self.attach_elastic_ips(meal, server)
    puts "Attaching elastic IPs..."
    ips = meal[:elastic_ips] || []

    ips.each do |ip|
      puts "Associating #{server.id} with #{ip}"
      compute.associate_address(server.id, ip)
    end
  end

  private

  def self.cook_meal_on_server(meal, server)
    puts "Cooking meal '#{meal[:name]}' on server: #{server}"
    Boucher.cook_meal(server, meal[:name])
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

  def self.create_meal_server(meal)
    server = compute.servers.new(:tags => {})
    Boucher.setup_meal(server, meal)
    server.save
    Boucher.print_servers([server])
    server
  end

  def self.create_volumes(meal, server)
    Array(meal[:volumes]).map do |volume_name|
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
