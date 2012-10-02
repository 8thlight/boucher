require 'boucher/addresses'

namespace :addresses do

  desc "Prints a list of allocated Elastic IP addresses"
  task :list do
    Boucher.print_address_overview(Boucher.address_overview)
  end

  desc "Allocates a new Elastic IP address"
  task :allocate do
    puts "Allocation a new Elastic IP address..."
    address = Boucher.compute.addresses.create
    Boucher.print_addresses([address])
  end

  desc "Releases an Elastic IP address"
  task :deallocate, [:ip] do |t, args|
    puts "Deallocating Elastic IP address: #{args.ip} ..."
    address = Boucher.compute.addresses.get(args.ip)
    raise "Elastic IP address not found: #{args.ip}" unless address
    address.destroy
    puts "Done."
  end

  desc "Associates an Elastic IP with a specific server"
  task :associate, [:ip, :server_id] do |t, args|
    server = Boucher.compute.servers.get(args.server_id)
    raise "Server not found!" unless server
    address = Boucher.compute.addresses.get(args.ip)
    raise "Elastic IP not found!" unless address
    address.server = server
    Boucher.print_addresses [address]
  end

  desc "Associates all unbound Elastic IP addresses configured for all meals"
  task :sync do
    Boucher.associate_all_addresses
  end


end