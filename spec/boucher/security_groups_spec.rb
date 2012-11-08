require_relative "../spec_helper"
require 'boucher/security_groups'
describe "Boucher Security Groups" do
  before :each do
    Fog::Compute.new({:provider => "AWS", :aws_access_key_id => "a", :aws_secret_access_key => "abc"})
  end

  it "finds all security groups" do
    first_security_group = Fog::Compute::AWS::SecurityGroup.new
    second_security_group = Fog::Compute::AWS::SecurityGroup.new

    first_security_group.name = "first"

    security_groups = [
      first_security_group,
      second_security_group
    ]

    Boucher.compute.stub(:security_groups).and_return(security_groups)
    Boucher::SecurityGroups.all.size.should == 2
    Boucher::SecurityGroups.all.first.name.should == "first"
  end

  it "finds the servers for each group" do
    first_security_group = Fog::Compute::AWS::SecurityGroup.new
    second_security_group = Fog::Compute::AWS::SecurityGroup.new

    first_security_group.name = "first"
    second_security_group.name = "second"

    Boucher::Servers.stub(:with_group).with("first").and_return(["a", "b"])
    Boucher::Servers.stub(:with_group).with("second").and_return(["b", "c"])

    security_groups = [
      first_security_group,
      second_security_group
    ]

    Boucher.compute.stub(:security_groups).and_return(security_groups)

    Boucher::SecurityGroups.servers_for_groups.should == {
      "first" => ["a", "b"],
      "second" => ["b", "c"],
    }
  end

  it "transforms 'all-ips' by putting funny 0 on the end" do
    Boucher::SecurityGroups.transform_ip("0.0.0.0").should == "0.0.0.0/0"
  end

  it "transforms other ip by putting funny 32 on the end" do
    Boucher::SecurityGroups.transform_ip("0.2.0.0").should == "0.2.0.0/32"
  end

  it "creates a security group according to configuration" do
    configuration = {
      name: "group",
      description: "group description",
      ip_permissions: [
        {
          from_port: 10,
          to_port: 11,
          protocol: "myprotocol",
          incoming_ip: "1.2.3.4"
        }
      ]
    }
    security_groups = mock(get: nil)
    Boucher.compute.stub(:security_groups).and_return(security_groups)
    new_group = mock
    expected_construction_args = {name: "group", description: "group description"}
    security_groups.should_receive(:new).with(expected_construction_args).and_return(new_group)
    new_group.should_receive(:authorize_port_range).with(10..11, cidr_ip: "1.2.3.4/32")
    Boucher::SecurityGroups.build_for_configuration(configuration)
  end

  it "creates a security group authorizing a different group" do
    configuration = {
      name: "group",
      description: "group description",
      ip_permissions: [
        {
          group: "zanzibar",
          from_port: 10,
          to_port: 11,
        }
      ]
    }
    security_groups = mock(get: nil)
    Boucher.compute.stub(:security_groups).and_return(security_groups)
    new_group = mock
    security_groups.stub(:new).and_return(new_group)
    new_group.should_receive(:authorize_port_range).with(10..11, group: "zanzibar")
    Boucher::SecurityGroups.build_for_configuration(configuration)
  end

  it "creates a security group with multiple ip_permissions" do
    configuration = {
      name: "group",
      description: "group description",
      ip_permissions: [
        {
          from_port: 10,
          to_port: 11,
          incoming_ip: "1.2.3.4"
        },
        {
          from_port: 90,
          to_port: 91,
          ip_protocol: "http",
          incoming_ip: "5.6.7.8"
        }
      ]
    }
    security_groups = mock(get: nil)
    Boucher.compute.stub(:security_groups).and_return(security_groups)
    new_group = mock
    expected_construction_args = {name: "group", description: "group description"}
    security_groups.should_receive(:new).with(expected_construction_args).and_return(new_group)
    new_group.should_receive(:authorize_port_range).with(10..11, cidr_ip: "1.2.3.4/32")
    new_group.should_receive(:authorize_port_range).with(90..91, cidr_ip: "5.6.7.8/32", ip_protocol: "http")
    Boucher::SecurityGroups.build_for_configuration(configuration)
  end

  it "Creates multiple security groups according to configurations" do
    configuration = {
      name: "group",
      description: "group description",
      ip_permissions: [
        {
          from_port: 10,
          to_port: 11,
          protocol: "myprotocol",
          incomingIP: "1.2.3.4/32"
        }
      ]
    }
    configurations = [configuration, configuration, configuration]
    security_groups = mock(get: nil)
    Boucher.compute.stub(:security_groups).and_return(security_groups)
    security_groups.stub(:new).and_return(mock(authorize_port_range: nil))
    security_groups.should_receive(:new).exactly(3).times
    Boucher::SecurityGroups.build_for_configurations(configurations)
  end

  it "destroys existing security groups and builds new ones over their graves" do
    groups = [Fog::Compute::AWS::SecurityGroup.new("name"=>"exists")]
    groups.stub(:new).and_return(stub(authorize_port_range: nil))
    groups.stub(:get).with("exists").and_return(groups.first)
    Boucher.compute.stub(:security_groups).and_return(groups)
    colliding_configuration = {
      name: "exists",
      description: "group description",
      ip_permissions: [
        {
          from_port: 10,
          to_port: 11,
          protocol: "myprotocol",
          incoming_ip: "1.2.3.4"
        }
      ]
    }
    groups.first.should_receive(:destroy)
    Boucher::SecurityGroups.build_for_configuration(colliding_configuration)
  end

  it "associates security groups and servers" do
    server_security_group_mapping = {
      "irc" => ["first"]
    }
    first_server = mock(tags: {"Name" => "irc"})
    first_server.should_receive(:groups=).with(["first"])
    second_server = mock(tags: {"Name" => "artisan"})
    Boucher::Servers.stub(:all).and_return([first_server, second_server])

    Boucher::SecurityGroups.associate_servers(server_security_group_mapping)
  end
end
