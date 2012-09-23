require 'butcher/compute'
require 'butcher/io'
require 'butcher/servers'
require 'butcher/volumes'
require 'butcher/nagios'
require 'retryable'

module Butcher
  def self.each_required_server(&block)
    Butcher::Config[:servers].each do |server_class|
      server = find_server(server_class, Butcher::Config[:env])
      block.yield(server, server_class)
    end
  end

  def self.get_server(server_class, environment, state)
    begin
      Butcher::Servers.find(:env => environment.to_s, :class => server_class, :state => state)
    rescue Butcher::Servers::NotFound
      nil
    end
  end

  def self.find_server(server_class, environment)
    get_server(server_class, environment, "stopped") || get_server(server_class, environment, "running")
  end

  def self.establish_all_servers
    Butcher.each_required_server do |server, server_class|
      # Retries after 2, 4, 8, 16, 32, and 64 seconds
      retryable(:tries => 6, :sleep => lambda { |n| 2**n }) do
        # A RuntimeError will sometimes be thrown here, with a message of:
        # "command failed with code 255"
        Butcher.establish_server(server, server_class)
      end
    end
  end

  def self.establish_server(server, server_class)
    if server.nil?
      Butcher.provision(server_class, Butcher.server_classes[server_class.to_sym])
    elsif server.state == "stopped"
      Butcher::Servers.start(server.id)
      server.reload
      Butcher.cook_meals_on_server(server_class, Butcher.server_classes[server_class.to_sym], server)
    else
      Butcher.cook_meals_on_server(server_class, Butcher.server_classes[server_class.to_sym], server)
    end
  end

  def self.provision(class_name, class_map)
    puts "Provisioning new #{class_name} server..."
    server = create_classified_server(class_map)
    wait_for_server_to_boot(server)
    wait_for_server_to_accept_ssh(server)
    volumes = create_volumes(class_map, server)
    attach_volumes(volumes, server)
    cook_meals_on_server(class_name, class_map, server)
    puts "\nThe new #{class_name} server has been provisioned! id: #{server.id}"
  end

  def self.attach_elastic_ips(class_name, server)
    puts "Attaching elastic IPs..."
    return unless Butcher::Config[:elastic_ips] && Butcher::Config[:elastic_ips][class_name]

    puts "Associating #{server.id} with #{Butcher::Config[:elastic_ips][class_name]}"
    compute.associate_address(server.id, Butcher::Config[:elastic_ips][class_name])
  end

  private

  def self.cook_meals_on_server(class_name, class_map, server)
    return unless class_map[:meals]

    class_map[:meals].each do |meal|
      meal = meal.call if meal.is_a?(Proc)
      Butcher.cook_meal(server, meal)
    end

    attach_elastic_ips(class_name, server)
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
    Butcher.print_servers([server])
  end

  def self.create_classified_server(class_map)
    server = compute.servers.new(:tags => {})
    Butcher.classify(server, class_map)
    server.save
    Butcher.print_servers([server])
    server
  end

  def self.create_volumes(class_map, server)
    Array(class_map[:volumes]).map do |volume_name|
      attributes = Butcher.volume_configs[volume_name]
      snapshot = snapshots.get(attributes[:snapshot])
      puts "Creating volume from snapshot #{snapshot.id}..."
      Butcher::Volumes.create(server.availability_zone, snapshot, attributes[:device])
    end
  end

  def self.attach_volumes(volumes, server)
    volumes.each do |volume|
      print "Attaching volume #{volume.id} to #{server.id}..."
      Butcher::Volumes.attach(volume, server)
      volume.wait_for { print "."; state == "in-use" }
      puts
    end
  end
end
