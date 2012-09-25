require_relative "../spec_helper"
require 'boucher/compute'
require 'boucher/nagios'
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
    server = OpenStruct.new(:dns_name => "test_dns")

    system "echo > /dev/null" # to populate $?
    Kernel.should_receive(:system).with("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{Boucher::Config[:aws_key_filename]}.pem #{Boucher::Config[:username]}@test_dns \"some command\"")

    Boucher.ssh(server, "some command")
  end

  it "downloads a file" do
    server = stub(:dns_name => "test_dns")
    Kernel.should_receive(:system).with("rsync", "-azb", "-e", Boucher.ssh_command, "--delete-after", "#{Boucher::Config[:username]}@test_dns:/usr/lib/a_file.txt", "/usr/local/local_file.txt")
    Boucher.download(server, "/usr/lib/a_file.txt", "/usr/local/local_file.txt")
  end

  it "rsyncs files" do
    server = stub(:dns_name => "test_dns")

    system "echo > /dev/null" # to populate $?
    Kernel.should_receive(:system).with("rsync", "-azb", "-e", Boucher.ssh_command,
      "--delete-after", "foo", "#{Boucher::Config[:username]}@test_dns:bar")

    Boucher.rsync(server, "foo", "bar")
  end

  it "opens an ssh shell" do
    server = OpenStruct.new(:dns_name => "test_dns")

    system "echo > /dev/null" # to populate $?
    Kernel.should_receive(:system).with("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{Boucher::Config[:aws_key_filename]}.pem #{Boucher::Config[:username]}@test_dns ")

    Boucher.ssh(server)
  end

  it "updates recipes and rsyncs local changes" do
    server = OpenStruct.new(:id => "test_id")
    Boucher.should_receive(:ssh).with(server, "cd infrastructure && git checkout . && git clean -d -f && git pull && bundle")
    Boucher.should_receive(:rsync).with(server, "cookbooks/", "infrastructure/cookbooks/")
    Boucher.should_receive(:rsync).with(server, "config/", "infrastructure/config/")
    Boucher.should_receive(:rsync).with(server, "tasks/", "infrastructure/tasks/")

    Boucher.update_recipes(server)
  end

  it "cooks a meal" do
    server = OpenStruct.new(:id => "test_id")

    Boucher.should_receive(:update_recipes).with(server)
    Boucher.should_receive(:ssh).with(server, "cd infrastructure && sudo BUTCHER_ENV=env_name BRANCH=branch_name chef-solo -c config/solo.rb -j config/meal_name.json")
    Boucher::Nagios.should_receive(:remove_host).with(server)
    Boucher::Nagios.should_receive(:add_host).with(server)
    Boucher::Config[:branch] = "branch_name"
    Boucher::Config[:env] = "env_name"

    Boucher.cook_meal(server, "meal_name")
  end
end
