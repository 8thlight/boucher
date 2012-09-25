require_relative "../spec_helper"
require 'boucher/provision'

describe "Boucher Provisioning" do

  before do
    Boucher::Config[:elastic_ips] = nil
  end

  after do
    Boucher::Config[:env] = "test"
  end

  describe "establish server" do
    it "provisions a server if one does not exist" do
      Boucher.should_receive(:meal).with("some_meal").and_return(:meal)
      Boucher.should_receive(:provision).with(:meal)

      Boucher.establish_server nil, "some_meal"
    end

    it "starts a server if it is stopped" do
      server = mock(:id => "the id", :state => "stopped")
      meal = {:name => "some_meal"}
      Boucher.stub(:meal).and_return(meal)
      Boucher.should_receive(:change_server_state).with("the id", :start, "running")
      server.should_receive(:reload)
      Boucher.should_receive(:cook_meal_on_server).with(meal, server)

      Boucher.establish_server server, "some_meal"
    end

    it "attaches elastic IPs if the server was stopped" do
      server = mock(:id => "the id", :state => "stopped", :reload => nil)
      Boucher.stub(:meal).and_return({:name => "some_meal", :elastic_ips => %w(1.2.3.4)})
      Boucher.stub(:change_server_state)
      Boucher.stub(:cook_meal)
      Boucher.compute.should_receive(:associate_address).with(anything, "1.2.3.4")

      Boucher.establish_server server, "meal_name"
    end

    it "cooks meals on server if it is up and running" do
      running_server = mock(:id => "the id", :state => "running")
      meal = {:name => "some_meal"}
      Boucher.stub(:meal).and_return(meal)
      Boucher.should_receive(:cook_meal_on_server).with(meal, running_server)

      Boucher.establish_server running_server, "some_meal"
    end
  end

  describe "provision" do
    it "provisions a server" do
      Boucher.stub!(:ssh)
      Boucher.should_receive(:setup_meal)
      Boucher.should_receive(:cook_meal).with(anything, "some_meal")

      Boucher.provision :name => "some_meal"
    end

    it "provisions a server with elastic IP" do
      Boucher.stub!(:ssh)
      Boucher.should_receive(:setup_meal)
      Boucher.stub(:cook_meal)
      Boucher.compute.should_receive(:associate_address).with(anything, "1.2.3.4")

      Boucher.provision :name => "some_meal", :elastic_ips => %w(1.2.3.4)
    end
  end
end
