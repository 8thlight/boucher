require_relative "../spec_helper"
require 'boucher/security_groups'

describe "Boucher Security Groups" do

  it "finds all security groups" do
    zz = Fog::Compute::AWS::SecurityGroup
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


end
