require_relative "../spec_helper"
require 'boucher/addresses'
require 'ostruct'

describe "Boucher Addresses" do

  before do
    Boucher::Servers.clear
  end

  after do
    Boucher::Servers.all.each { |s| s.destroy }
    Boucher::Config[:env] = "dev"
  end

  it "does nothing for meal with no elastic ips" do
    server = Boucher.compute.servers.create(tags: {"Meal" => "some_meal"})

    Boucher.associate_addresses_for({name: "some_meal"}, server)

    server.reload
    server.addresses.should == []
  end

  it "associates ips for server" do
    server = Boucher.compute.servers.create(tags: {"Meal" => "some_meal"})
    ip = Boucher.compute.addresses.create

    meal = {name: "some_meal", elastic_ips: [ip.public_ip]}
    Boucher.associate_addresses_for(meal, server)

    server.reload
    server.addresses.count.should == 1
    server.addresses.first.public_ip.should == ip.public_ip
  end

  it "associating ips skips missing ips" do
    server = Boucher.compute.servers.create(tags: {"Meal" => "some_meal"})

    meal = {name: "some_meal", elastic_ips: ["1.2.3.4"]}

    lambda { Boucher.associate_addresses_for(meal, server) }.should_not raise_error
  end

  it "associates all ips for all meals" do
    server1 = Boucher.compute.servers.create(tags: {"Meal" => "meal1", "Env" => "dev"})
    server2 = Boucher.compute.servers.create(tags: {"Meal" => "meal2", "Env" => "dev"})
    ip1 = Boucher.compute.addresses.create
    ip2 = Boucher.compute.addresses.create

    meals = {meal1: {name: "meal1", elastic_ips: [ip1.public_ip]},
             meal2: {name: "meal2", elastic_ips: [ip2.public_ip]}}
    Boucher.stub(:meals).and_return meals

    Boucher.associate_all_addresses

    server1.reload
    server1.addresses.size.should == 1
    server1.addresses.first.public_ip.should == ip1.public_ip
    server2.reload
    server2.addresses.first.public_ip.should == ip2.public_ip
  end

  it "associate all with missing server doesn't crash" do
    ip = Boucher.compute.addresses.create

    Boucher.meals[:some_meal] = {name: "some_meal", elastic_ips: [ip.public_ip]}

    lambda { Boucher.associate_all_addresses }.should_not raise_error
  end


end