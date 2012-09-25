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
      Boucher.stub(:meals).and_return({:class_of_server => "server details"})
      Boucher.should_receive(:provision).with("class_of_server", "server details")

      Boucher.establish_server nil, "class_of_server"
    end

    it "starts a server if it is stopped" do
      server = mock(:id => "the id", :state => "stopped")
      Boucher.stub(:meals).and_return({:class_of_server => "server details"})
      Boucher.should_receive(:change_server_state).with("the id", :start, "running")
      server.should_receive(:reload)
      Boucher.should_receive(:cook_meals_on_server).with("class_of_server", "server details", server)

      Boucher.establish_server server, "class_of_server"
    end

    it "attaches elastic IPs if the server was stopped" do
      Boucher::Config[:elastic_ips] = { "class_of_server" => "1.2.3.4" }
      server = mock(:id => "the id", :state => "stopped", :reload => nil)
      Boucher.stub(:meals).and_return({:class_of_server => {:meals => []}})
      Boucher.stub(:change_server_state)
      Boucher.compute.should_receive(:associate_address).with(anything, "1.2.3.4")

      Boucher.establish_server server, "class_of_server"
    end

    it "cooks meals on server if it is up and running" do
      running_server = mock(:id => "the id", :state => "running")
      Boucher.stub(:meals).and_return({:class_of_server => "server details"})
      Boucher.should_receive(:cook_meals_on_server).with("class_of_server", "server details", running_server)

      Boucher.establish_server running_server, "class_of_server"
    end
  end

  describe "provision" do
    it "provisions a server" do
      Boucher.stub!(:ssh)
      Boucher.should_receive(:setup_meal)
      Boucher.should_receive(:cook_meal).with(anything, "foo")

      Boucher.provision "foo", {:meals => ["foo"]}
    end

    it "provisions a server with Procs as meals" do
      Boucher.stub!(:ssh)
      Boucher.should_receive(:setup_meal)
      Boucher.should_receive(:cook_meal).with(anything, "foo")

      Boucher.provision "foo", {:meals => [lambda{"foo"}]}
    end

    it "provisions a server with elastic IP" do
      Boucher.stub!(:ssh)
      Boucher::Config[:elastic_ips] = { "foo" => "1.2.3.4" }
      Boucher.should_receive(:setup_meal)
      Boucher.compute.should_receive(:associate_address).with(anything, "1.2.3.4")

      Boucher.provision "foo", {:meals => []}
    end
  end
end
