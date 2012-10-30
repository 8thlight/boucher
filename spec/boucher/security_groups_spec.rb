require_relative "../spec_helper"
require 'boucher/security_groups'

describe "Boucher Security Groups" do

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
          from_port: 10,
          to_port: 11,
          protocol: "myprotocol",
          incomingIP: "12345"
        }
      ]
    }
    fog_arguments=nil
    security_groups = mock
    Boucher.compute.stub(:security_groups).and_return(security_groups)
    security_groups.should_receive(:new).with(fog_arguments)
    security_groups.should_receive(:save)
  end
end
