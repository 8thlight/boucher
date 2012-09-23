require_relative "../spec_helper"
require 'butcher/provision'

describe "Butcher Provisioning" do

  before do
    Butcher::Config[:elastic_ips] = nil
  end

  after do
    Butcher::Config[:env] = "test"
  end

  describe "establish server" do
    it "provisions a server if one does not exist" do
      Butcher.stub(:server_classes).and_return({:class_of_server => "server details"})
      Butcher.should_receive(:provision).with("class_of_server", "server details")

      Butcher.establish_server nil, "class_of_server"
    end

    it "starts a server if it is stopped" do
      server = mock(:id => "the id", :state => "stopped")
      Butcher.stub(:server_classes).and_return({:class_of_server => "server details"})
      Butcher.should_receive(:change_server_state).with("the id", :start, "running")
      server.should_receive(:reload)
      Butcher.should_receive(:cook_meals_on_server).with("class_of_server", "server details", server)

      Butcher.establish_server server, "class_of_server"
    end

    it "attaches elastic IPs if the server was stopped" do
      Butcher::Config[:elastic_ips] = { "class_of_server" => "1.2.3.4" }
      server = mock(:id => "the id", :state => "stopped", :reload => nil)
      Butcher.stub(:server_classes).and_return({:class_of_server => {:meals => []}})
      Butcher.stub(:change_server_state)
      Butcher.compute.should_receive(:associate_address).with(anything, "1.2.3.4")

      Butcher.establish_server server, "class_of_server"
    end

    it "cooks meals on server if it is up and running" do
      running_server = mock(:id => "the id", :state => "running")
      Butcher.stub(:server_classes).and_return({:class_of_server => "server details"})
      Butcher.should_receive(:cook_meals_on_server).with("class_of_server", "server details", running_server)

      Butcher.establish_server running_server, "class_of_server"
    end
  end

  describe "provision" do
    it "provisions a server" do
      Butcher.stub!(:ssh)
      Butcher.should_receive(:classify)
      Butcher.should_receive(:cook_meal).with(anything, "foo")

      Butcher.provision "foo", {:meals => ["foo"]}
    end

    it "provisions a server with Procs as meals" do
      Butcher.stub!(:ssh)
      Butcher.should_receive(:classify)
      Butcher.should_receive(:cook_meal).with(anything, "foo")

      Butcher.provision "foo", {:meals => [lambda{"foo"}]}
    end

    it "provisions a server with elastic IP" do
      Butcher.stub!(:ssh)
      Butcher::Config[:elastic_ips] = { "foo" => "1.2.3.4" }
      Butcher.should_receive(:classify)
      Butcher.compute.should_receive(:associate_address).with(anything, "1.2.3.4")

      Butcher.provision "foo", {:meals => []}
    end
  end
end
