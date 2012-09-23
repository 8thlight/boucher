require_relative "../spec_helper"
require 'butcher/servers'
require 'ostruct'

describe "Butcher::Servers" do

  let(:remote_servers) {
    [OpenStruct.new(:id => "s1", :tags => {"Env" => "test", "Class" => "foo"}, :state => "stopped"),
     OpenStruct.new(:id => "s2", :tags => {"Env" => "test", "Class" => "bar"}, :state => "pending"),
     OpenStruct.new(:id => "s3", :tags => {"Env" => "dev",  "Class" => "foo"}, :state => "terminated"),
     OpenStruct.new(:id => "s4", :tags => {"Env" => "dev",  "Class" => "bar"}, :state => "running")]
  }

  before do
    @env = Butcher::Config[:env]
    Butcher.compute.stub(:servers).and_return(remote_servers)
  end

  after do
    Butcher::Config[:env] = @env
  end

  it "finds all servers" do
    Butcher::Servers.all.size.should == 4
    Butcher::Servers.all.should == remote_servers
  end

  it "finds classed servers" do
    Butcher::Servers.of_class("blah").should == []
    Butcher::Servers.of_class(:foo).map(&:id).should == ["s1", "s3"]
    Butcher::Servers.of_class("bar").map(&:id).should == ["s2", "s4"]
  end

  it "finds with env servers" do
    Butcher::Servers.in_env("blah").should == []
    Butcher::Servers.in_env("test").map(&:id).should == ["s1", "s2"]
    Butcher::Servers.in_env("dev").map(&:id).should == ["s3", "s4"]
  end

  it "finds servers in a given state" do
    Butcher::Servers.in_state("running").map(&:id).should == ["s4"]
    Butcher::Servers.in_state("terminated").map(&:id).should == ["s3"]
    Butcher::Servers.in_state("pending").map(&:id).should == ["s2"]
    Butcher::Servers.in_state("stopped").map(&:id).should == ["s1"]
  end

  it "finds the first matching server" do
    Butcher::Servers.find.id.should == "s1"
    Butcher::Servers.find(:class => "foo").id.should == "s1"
    Butcher::Servers.find(:class => "bar").id.should == "s2"
    Butcher::Servers.find(:env => "test").id.should == "s1"
    Butcher::Servers.find(:env => "dev").id.should == "s3"
    Butcher::Servers.find(:class => "foo", :env => "test").id.should == "s1"
    Butcher::Servers.find(:class => "foo", :env => "dev").id.should == "s3"
    Butcher::Servers.find(:class => "bar", :env => "test").id.should == "s2"
    Butcher::Servers.find(:class => "bar", :env => "dev").id.should == "s4"
    expect { Butcher::Servers.find(:class => "blah", :env => "dev") }.to raise_error
    expect { Butcher::Servers.find(:class => "foo", :env => "blah") }.to raise_error
  end

  it "raises an error if find returns no results" do
    expect { Butcher::Servers.find(:class => "blah") }.to raise_error(Butcher::Servers::NotFound)
  end

  it "gets a server based on current env when all the servers are running" do
    Butcher::Config[:env] = "test"
    expect { Butcher::Servers["foo"] }.to raise_error
    expect { Butcher::Servers["bar"] }.to raise_error

    Butcher::Config[:env] = "dev"
    expect { Butcher::Servers["foo"] }.to raise_error
    Butcher::Servers["bar"].id.should == "s4"
  end

  it "stops a server" do
    Butcher.should_receive(:change_server_state).with("the id", :stop, "stopped")
    Butcher::Servers.stop("the id")
  end
end
