require 'boucher/addresses'

namespace :addresses do

  desc "Prints a list of allocated Elastic IP addresses"
  task :list do
    Boucher.print_addresses(Boucher.compute.addresses)
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

  desc "Associates Elastic IP addresses configured for the specified meal"
  task :associate, [:ip, :server_id] do |t, args|
  end

  desc "Associates all unbound Elastic IP addresses configured for all meals"
  task :associate_all do

  end


end