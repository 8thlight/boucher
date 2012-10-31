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
          incomingIPs: ["12345", "1999"]
        }
      ]
    }
    fog_arguments = {
      name: "group",
      description: "group description",
      ip_permissions: [
        {
          ipRanges: [{cidrIp: "12345"}, {cidrIp: "1999"}],
          groups: [],
          from_port: 10,
          to_port: 11,
          ipProtocol: "myprotocol",
        }
      ]
    }
    security_groups = mock(find: nil)
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
          ipRanges: [{cidrIp: "12345"}, {cidrIp: "1999"}],
          groups: [],
          from_port: 10,
          to_port: 11,
          ipProtocol: "myprotocol",
        }
      ]
    }
    configurations = [configuration, configuration, configuration]
    transformed_configurations = [fog_arguments, fog_arguments, fog_arguments]
    security_groups = mock(find: nil)
    Boucher.compute.stub(:security_groups).and_return(security_groups)
    security_groups.should_receive(:new).with(fog_arguments).and_return(mock(save: nil))
    security_groups.should_receive(:new).with(fog_arguments).and_return(mock(save: nil))
    security_groups.should_receive(:new).with(fog_arguments).and_return(mock(save: nil))
    Boucher::SecurityGroups.build_for_configurations(configurations)
  end

  it "updates existing security groups" do
    groups = [Fog::Compute::AWS::SecurityGroup.new("name"=>"exists")]
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
    configurations = [non_colliding_configuration, colliding_configuration]
    groups.should_receive(:new).and_return(stub(:save => nil))
    groups.first.should_receive(:merge_attributes).and_return(stub(:save => nil))

    Boucher::SecurityGroups.build_for_configurations(configurations)

  end
end
