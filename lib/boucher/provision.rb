require 'boucher/compute'
require 'boucher/io'
require 'boucher/servers'
require 'boucher/volumes'
require 'boucher/addresses'
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
      Boucher::Servers.start([server])
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
    attach_volumes(meal, server)
    cook_meal_on_server(meal, server)
    puts "\nThe new #{meal[:name]} server has been provisioned! id: #{server.id}"
  end

  private

  def self.cook_meal_on_server(meal, server)
    puts "Cooking meal '#{meal[:name]}' on server: #{server}"
    Boucher.cook_meal(server, meal[:name])
    associate_addresses_for(meal, server)
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

  def self.attach_volumes(meal, server)
    volumes = meal[:volumes]
    return unless volumes && volumes.size > 0
    puts "Attaching volumes..."
    volumes.each do |device, spec|
      volume = acquire_volume(spec, server)
      print "Attaching volume #{volume.id} to #{server.id}..."
      Boucher.compute.attach_volume(server.id, volume.id, device)
      volume.wait_for { print "."; volume.state == "in-use" }
      puts
    end
  end

  def self.acquire_volume(spec, server)
    if spec[:volume_id]
      Boucher.compute.volumes.get(spec[:volume_id])
    elsif spec[:snapshot_id]
      puts "Creating volume based on snapshot: #{spec[:snapshot_id]}"
      Boucher::Volumes.create(:snapshot_id => spec[:snapshot_id], :availability_zone => server.availability_zone)
    else
      puts "Creating new volume of size: #{spec[:size]}GB"
      Boucher::Volumes.create(:size => spec[:size].to_i, :availability_zone => server.availability_zone)
    end
  end
end
