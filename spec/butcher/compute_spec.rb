require_relative "../spec_helper"
require 'butcher/compute'
require 'butcher/nagios'
require 'ostruct'

describe "Butcher Cloud" do

  after do
    Butcher::Config[:env] = "dev"
  end

  it "knows connections options" do
    connection = Butcher.compute
    connection.should_not == nil
    Butcher::EC2_CONFIG[:aws_secret_access_key].should == "secret key"
    Butcher::EC2_CONFIG[:aws_access_key_id].should == "public id"
  end

  it "ssh's a command" do
    server = OpenStruct.new(:dns_name => "test_dns")

    system "echo > /dev/null" # to populate $?
    Kernel.should_receive(:system).with("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{Butcher::Config[:aws_key_filename]}.pem #{Butcher::Config[:username]}@test_dns \"some command\"")

    Butcher.ssh(server, "some command")
  end

  it "downloads a file" do
    server = stub(:dns_name => "test_dns")
    Kernel.should_receive(:system).with("rsync", "-azb", "-e", Butcher.ssh_command, "--delete-after", "#{Butcher::Config[:username]}@test_dns:/usr/lib/a_file.txt", "/usr/local/local_file.txt")
    Butcher.download(server, "/usr/lib/a_file.txt", "/usr/local/local_file.txt")
  end

  it "rsyncs files" do
    server = stub(:dns_name => "test_dns")

    system "echo > /dev/null" # to populate $?
    Kernel.should_receive(:system).with("rsync", "-azb", "-e", Butcher.ssh_command,
      "--delete-after", "foo", "#{Butcher::Config[:username]}@test_dns:bar")

    Butcher.rsync(server, "foo", "bar")
  end

  it "opens an ssh shell" do
    server = OpenStruct.new(:dns_name => "test_dns")

    system "echo > /dev/null" # to populate $?
    Kernel.should_receive(:system).with("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{Butcher::Config[:aws_key_filename]}.pem #{Butcher::Config[:username]}@test_dns ")

    Butcher.ssh(server)
  end

  it "updates recipes and rsyncs local changes" do
    server = OpenStruct.new(:id => "test_id")
    Butcher.should_receive(:ssh).with(server, "cd infrastructure && git checkout . && git clean -d -f && git pull && bundle")
    Butcher.should_receive(:rsync).with(server, "cookbooks/", "infrastructure/cookbooks/")
    Butcher.should_receive(:rsync).with(server, "config/", "infrastructure/config/")
    Butcher.should_receive(:rsync).with(server, "tasks/", "infrastructure/tasks/")

    Butcher.update_recipes(server)
  end

  it "cooks a meal" do
    server = OpenStruct.new(:id => "test_id")

    Butcher.should_receive(:update_recipes).with(server)
    Butcher.should_receive(:ssh).with(server, "cd infrastructure && sudo BUTCHER_ENV=env_name BRANCH=branch_name chef-solo -c config/solo.rb -j config/meal_name.json")
    Butcher::Nagios.should_receive(:remove_host).with(server)
    Butcher::Nagios.should_receive(:add_host).with(server)
    Butcher::Config[:branch] = "branch_name"
    Butcher::Config[:env] = "env_name"

    Butcher.cook_meal(server, "meal_name")
  end
end
