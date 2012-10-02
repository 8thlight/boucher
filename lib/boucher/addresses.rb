require 'boucher/compute'
require 'boucher/servers'

module Boucher

  ADDRESS_TABLE_FORMAT = "%-15s  %-12s\n"

  def self.print_addresses(addresses)
    puts
    printf ADDRESS_TABLE_FORMAT, "Public IP", "Server ID"
    puts ("-" * 29)

    addresses.each do |address|
      printf VOLUME_TABLE_FORMAT,
             address.public_ip,
             address.server_id
    end
  end

  def self.associate_addresses_for(meal, server)
    ips = meal[:elastic_ips]
    if ips.nil? || ips.empty?
      puts "No Elastic IPs to associate for meal #{meal[:name]}."
      return
    end
    ips.each do |ip|
      address = Boucher.compute.addresses.get(ip)
      if address
        puts "Associating #{meal[:name]}:#{server.id} with #{ip}"
        address.server = server
      else
        puts "Elastic IP (#{ip}) not found. Skipping."
      end
    end
  end

  def self.associate_all_addresses
    meals = Boucher.meals
    meals.each do |name, meal|
      ips = meal[:elastic_ips]
      if ips && ips.size > 0
        begin
          server = Boucher::Servers.find(meal: name, env: Boucher::Config[:env])
          associate_addresses_for(meal, server)
        rescue Boucher::Servers::NotFound => e
          puts "Can't associate address to '#{name}' server because it can't be found."
        end
      end
    end
  end

end