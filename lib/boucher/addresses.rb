require 'boucher/compute'
require 'boucher/servers'

module Boucher

  ADDRESS_TABLE_FORMAT = "%-15s  %-12s\n"

  def self.print_addresses(addresses)
    puts
    printf ADDRESS_TABLE_FORMAT, "Public IP", "Server ID"
    puts ("-" * 29)

    addresses.each do |address|
      printf ADDRESS_TABLE_FORMAT,
             address.public_ip,
             address.server_id
    end
  end

  ADDRESS_OVERVIEW_TABLE_FORMAT = "%12s  %-15s  %-12s\n"

  def self.print_address_overview(addresses)
    puts
    printf ADDRESS_OVERVIEW_TABLE_FORMAT, "Meal", "Public IP", "Server ID"
    puts ("-" * 43)

    addresses.values.each do |address|
      printf ADDRESS_OVERVIEW_TABLE_FORMAT,
             address[:meal],
             address[:ip],
             address[:server_id]
    end
  end

  def self.address_overview
    ips = {}
    Boucher.compute.addresses.each do |ip|
      ips[ip.public_ip] = {ip: ip.public_ip, server_id: ip.server_id}
    end
    Boucher.meals.each do |name, meal|
      (meal[:elastic_ips] || []).each do |ip|
        if ip.nil? || ip.size == 0
          # skip
        elsif ips[ip]
          ips[ip][:meal] = name
        else
          ips[ip] = {meal: name, ip: ip}
        end
      end
    end
    ips
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
        if address.server_id == server.id
          puts "#{ip} already associated with #{meal[:name]}:#{server.id}"
        else
          puts "Associating #{ip} with #{meal[:name]}:#{server.id}"
          address.server = server
        end
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