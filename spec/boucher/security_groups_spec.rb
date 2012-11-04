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
          groups: [],
          from_port: 10,
          to_port: 11,
          protocol: "myprotocol",
          incomingIPs: ["1.2.3.4.5"]
        }
      ]
    }
    fog_arguments = {
      name: "group",
      description: "group description",
      ip_permissions: [
        {
          ipRanges: [{cidrIp: "1.2.3.4.5/32"}],
          groups: [],
          from_port: 10,
          to_port: 11,
          ipProtocol: "myprotocol",
        }
      ]
    }
    security_groups = mock(get: nil)
    new_group = mock
    Boucher.compute.stub(:security_groups).and_return(security_groups)
    security_groups.should_receive(:new).with(fog_arguments).and_return(new_group)
    new_group.should_receive(:save)
    Boucher::SecurityGroups.build_for_configuration(configuration)
  end

  it "Creates multiple security groups according to configurations" do
    configuration = {
      name: "group",
      description: "group description",
      ip_permissions: [
        {
          groups: [],
          from_port: 10,
          to_port: 11,
          protocol: "myprotocol",
          incomingIPs: ["12345", "1999"]
        }
      ]
    }
    fog_arguments = {
      name: "group",
      description: "group description",
      ip_permissions: [
        {
          ipRanges: [{cidrIp: "12345/32"}, {cidrIp: "1999/32"}],
          groups: [],
          from_port: 10,
          to_port: 11,
          ipProtocol: "myprotocol",
        }
      ]
    }
    configurations = [configuration, configuration, configuration]
    transformed_configurations = [fog_arguments, fog_arguments, fog_arguments]
    security_groups = mock(get: nil)
    Boucher.compute.stub(:security_groups).and_return(security_groups)
    security_groups.should_receive(:new).with(fog_arguments).and_return(mock(save: nil))
    security_groups.should_receive(:new).with(fog_arguments).and_return(mock(save: nil))
    security_groups.should_receive(:new).with(fog_arguments).and_return(mock(save: nil))
    Boucher::SecurityGroups.build_for_configurations(configurations)
  end

  it "updates existing security groups and builds a new group for not-existing ones" do
    groups = [Fog::Compute::AWS::SecurityGroup.new("name"=>"exists")]
    groups.stub(:get)
    groups.stub(:get).with("exists").and_return(groups.first)
    Boucher.compute.stub(:security_groups).and_return(groups)
    non_colliding_configuration = {
      name: "group",
      description: "group description",
      ip_permissions: [
        {
          groups: [],
          from_port: 10,
          to_port: 11,
          protocol: "myprotocol",
          incomingIPs: ["12345", "1999"]
        }
      ]
    }
    colliding_configuration = {
      name: "exists",
      description: "group description",
      ip_permissions: [
        {
          groups: [],
          from_port: 10,
          to_port: 11,
          protocol: "myprotocol",
          incomingIPs: ["12345", "1999"]
        }
      ]
    }
    transformed_colliding_config = Boucher::SecurityGroups.transform_configuration colliding_configuration
    transformed_non_collliding_config = Boucher::SecurityGroups.transform_configuration non_colliding_configuration

    configurations = [non_colliding_configuration, colliding_configuration]

    groups.first.should_receive(:merge_attributes)
                .with(transformed_colliding_config)
                .and_return(nil)
    groups.first.should_receive(:destroy)
    groups.first.should_receive(:save)

    groups.should_receive(:new)
                .with(transformed_non_collliding_config)
                .and_return(stub save: nil)

    Boucher::SecurityGroups.build_for_configurations(configurations)
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
