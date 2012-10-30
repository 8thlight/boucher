require_relative "../spec_helper"
require 'boucher/servers'
require 'ostruct'

describe "Boucher::Servers" do

  let(:remote_servers) {
    [OpenStruct.new(:id => "s1", :tags => {"Env" => "test", "Meal" => "foo"}, :state => "stopped"),
     OpenStruct.new(:id => "s2", :tags => {"Env" => "test", "Meal" => "bar"}, :state => "pending"),
     OpenStruct.new(:id => "s3", :tags => {"Env" => "dev",  "Meal" => "foo"}, :state => "terminated"),
     OpenStruct.new(:id => "s4", :tags => {"Env" => "dev",  "Meal" => "bar"}, :state => "running")]
  }

  before do
    @env = Boucher::Config[:env]
    Boucher.compute.stub(:servers).and_return(remote_servers)
  end

  after do
    Boucher::Config[:env] = @env
  end

  it "finds all servers" do
    Boucher::Servers.all.size.should == 4
    Boucher::Servers.all.should == remote_servers
  end

  it "finds mealed servers" do
    Boucher::Servers.of_meal("blah").should == []
    Boucher::Servers.of_meal(:foo).map(&:id).should == ["s1", "s3"]
    Boucher::Servers.of_meal("bar").map(&:id).should == ["s2", "s4"]
  end

  it "finds with env servers" do
    Boucher::Servers.in_env("blah").should == []
    Boucher::Servers.in_env("test").map(&:id).should == ["s1", "s2"]
    Boucher::Servers.in_env("dev").map(&:id).should == ["s3", "s4"]
  end

  it "finds servers with a given security group" do
    Boucher::Servers.clear
    remote_servers.each do |s|
      s.groups = []
    end
    remote_servers.first.groups = ["test"]

    Boucher::Servers.with_group("blah").should == []
    Boucher::Servers.with_group("test").map(&:id).should == ["s1"]
  end

  it "finds servers in a given state" do
    Boucher::Servers.in_state("running").map(&:id).should == ["s4"]
    Boucher::Servers.in_state("terminated").map(&:id).should == ["s3"]
    Boucher::Servers.in_state("pending").map(&:id).should == ["s2"]
    Boucher::Servers.in_state("stopped").map(&:id).should == ["s1"]
  end

  it "finds servers NOT in a given state" do
    Boucher::Servers.in_state("!running").map(&:id).should == %w(s1 s2 s3)
    Boucher::Servers.in_state("!terminated").map(&:id).should == %w(s1 s2 s4)
    Boucher::Servers.in_state("!pending").map(&:id).should == %w(s1 s3 s4)
    Boucher::Servers.in_state("!stopped").map(&:id).should == %w(s2 s3 s4)
  end

  it "finds the first matching server" do
    Boucher::Servers.find.id.should == "s1"
    Boucher::Servers.find(:meal => "foo").id.should == "s1"
    Boucher::Servers.find(:meal => "bar").id.should == "s2"
    Boucher::Servers.find(:env => "test").id.should == "s1"
    Boucher::Servers.find(:env => "dev").id.should == "s3"
    Boucher::Servers.find(:meal => "foo", :env => "test").id.should == "s1"
    Boucher::Servers.find(:meal => "foo", :env => "dev").id.should == "s3"
    Boucher::Servers.find(:meal => "bar", :env => "test").id.should == "s2"
    Boucher::Servers.find(:meal => "bar", :env => "dev").id.should == "s4"
    expect { Boucher::Servers.find(:meal => "blah", :env => "dev") }.to raise_error
    expect { Boucher::Servers.find(:meal => "foo", :env => "blah") }.to raise_error
  end

  it "raises an error if find returns no results" do
    expect { Boucher::Servers.find(:meal => "blah") }.to raise_error(Boucher::Servers::NotFound)
  end

  it "gets a server based on current env when all the servers are running" do
    Boucher::Config[:env] = "test"
    expect { Boucher::Servers["foo"] }.to raise_error
    expect { Boucher::Servers["bar"] }.to raise_error

    Boucher::Config[:env] = "dev"
    expect { Boucher::Servers["foo"] }.to raise_error
    Boucher::Servers["bar"].id.should == "s4"
  end

  it "stops a server" do
    server = OpenStruct.new(:id => "the id")
    Boucher.should_receive(:change_servers_state).with([server], :stop, "stopped")
    Boucher::Servers.stop([server])
  end
end
