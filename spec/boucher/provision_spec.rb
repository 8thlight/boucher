require_relative "../spec_helper"
require 'boucher/provision'

describe "Boucher Provisioning" do

  before do
    Boucher::Servers.clear
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
      Boucher.should_receive(:change_servers_state).with([server], :start, "running")
      server.should_receive(:reload)
      Boucher.should_receive(:cook_meal_on_server).with(meal, server)

      Boucher.establish_server server, "some_meal"
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
      Boucher.compute.key_pairs.create(name: "test_key")
      ip = Boucher.compute.addresses.create
      Boucher.stub!(:ssh)
      Boucher.stub!(:cook_meal)

      Boucher.provision :name => "some_meal", :elastic_ips => [ip.public_ip]

      server = Boucher::Servers["some_meal"]
      server.reload
      server.addresses.size.should == 1
      server.addresses.first.public_ip.should == ip.public_ip
    end

    it "attaches volumes" do
      Boucher.stub!(:ssh)
      Boucher.should_receive(:setup_meal)
      Boucher.stub(:cook_meals_on_server)

      Boucher.should_receive(:attach_volumes)

      Boucher.provision :name => "some_meal", :volumes => {}
    end
  end

  context "Volumes" do

    let(:server) { server = Boucher.compute.servers.new; server.save; server }

    it "attaches an existing volume" do
      volume = Boucher::Volumes.create(:size => 12, :availability_zone => "us-east-1c")

      meal_spec = {:volumes => {"/dev/sda2" => {:volume_id => volume.id}}}
      Boucher.attach_volumes(meal_spec, server)

      server.reload
      server.volumes.size.should == 1
      server.volumes.first.device.should == "/dev/sda2"
      server.volumes.first.availability_zone.should == "us-east-1c"
      server.volumes.first.size.should == 12
    end

    it "attaches a new volume based on a snapshot" do
      old_volume = Boucher::Volumes.create(:size => 12, :availability_zone => "us-east-1c")
      response = old_volume.snapshot("test")
      snapshot_id = response.body["snapshotId"]

      meal_spec = {:volumes => {"/dev/sda3" => {:snapshot_id => snapshot_id}}}
      Boucher.attach_volumes(meal_spec, server)

      server.reload
      server.volumes.size.should == 1
      volume = server.volumes.first
      volume.snapshot_id.should == snapshot_id
      volume.size.should == 12
      volume.device.should == "/dev/sda3"
    end

    it "attaches a new volume with specified size" do
      meal_spec = {:volumes => {"/dev/sda4" => {:size => 42}}}
      Boucher.attach_volumes(meal_spec, server)

      server.reload
      server.volumes.size.should == 1
      volume = server.volumes.first
      volume.size.should == 42
      volume.device.should == "/dev/sda4"
    end

  end
end
