require_relative "../spec_helper"
require 'boucher/compute'
require 'ostruct'

describe "Boucher Cloud" do

  after do
    Boucher::Config[:env] = "dev"
  end

  it "knows connections options" do
    connection = Boucher.compute
    connection.should_not == nil
    Boucher::EC2_CONFIG[:aws_secret_access_key].should == "secret key"
    Boucher::EC2_CONFIG[:aws_access_key_id].should == "public id"
  end

  it "ssh's a command" do
    server = OpenStruct.new(:dns_name => "test_dns", :tags => {})

    system "echo > /dev/null" # to populate $?
    Kernel.should_receive(:system).with("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{Boucher::Config[:aws_key_filename]}.pem #{Boucher::Config[:username]}@test_dns \"some command\"")

    Boucher.ssh(server, "some command")
  end

  it "opens an ssh shell" do
    server = OpenStruct.new(:dns_name => "test_dns", :tags => {})

    system "echo > /dev/null" # to populate $?
    Kernel.should_receive(:system).with("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{Boucher::Config[:aws_key_filename]}.pem #{Boucher::Config[:username]}@test_dns ")

    Boucher.ssh(server)
  end

  it "prefers the meal's username when it's available" do
    Boucher.stub(:meal).with("test_meal").and_return({:username => "json_specified_username"})
    server = OpenStruct.new(:dns_name => "test_dns", :tags => {"Meal" => "test_meal"})

    system "echo > /dev/null" # to populate $?
    Kernel.should_receive(:system).with("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{Boucher::Config[:aws_key_filename]}.pem json_specified_username@test_dns ")

    Boucher.ssh(server)
  end

  it "updates recipes" do
    server = OpenStruct.new(:id => "test_id", :tags => {})
    Boucher.should_receive(:ssh).with(server, "cd infrastructure && git checkout . && git clean -d -f && git pull && bundle")

    Boucher.update_recipes(server)
  end

  it "cooks a meal" do
    server = OpenStruct.new(:id => "test_id", :tags => {})

    Boucher.should_receive(:update_recipes).with(server)
    Boucher.should_receive(:ssh).with(server, "cd infrastructure && sudo BENV=env_name BRANCH=branch_name chef-solo -c config/solo.rb -j config/meal_name.json")
    Boucher::Config[:branch] = "branch_name"
    Boucher::Config[:env] = "env_name"

    Boucher.cook_meal(server, "meal_name")
  end
end
