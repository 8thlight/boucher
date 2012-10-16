require_relative "../spec_helper"
require 'boucher/volumes'
require 'ostruct'

describe "Boucher::Volumes" do

  context "with mocked volumes" do
    let(:remote_volumes) {
      [OpenStruct.new(:id => "v1", :tags => {"Name" => "1", "Meal" => "foo"}, :size => 8),
       OpenStruct.new(:id => "v2", :tags => {"Name" => "2", "Meal" => "bar"}, :size => 16),
       OpenStruct.new(:id => "v3", :tags => {"Name" => "3", "Meal" => "foo"}, :size => 32)]
    }

    before do
      Boucher.compute.stub(:volumes).and_return(remote_volumes)
    end

    after do
      Boucher::Config[:env] = "test"
    end

    it "finds all volumes" do
      Boucher::Volumes.all.size.should == 3
      Boucher::Volumes.all.should == remote_volumes
    end

    it "finds volumes by id" do
      Boucher::Volumes.with_id("v1").should == remote_volumes[0]
      Boucher::Volumes.with_id("v2").should == remote_volumes[1]
      Boucher::Volumes.with_id("v3").should == remote_volumes[2]
    end
  end

  it "creates a volume" do
    volume = Boucher::Volumes.create(:size => 12, :availability_zone => "us-east-1c")

    volume.availability_zone.should == "us-east-1c"
    volume.size.should == 12
  end

  it "creates a volume with snapshot" do
    volume = Boucher::Volumes.create(:size => 12, :availability_zone => "us-east-1c")
    response = volume.snapshot("test")

    new_volume = Boucher::Volumes.create(:snapshot_id => response.body["snapshotId"], :availability_zone => "us-east-1c")

    new_volume.size.should == 12
    new_volume.availability_zone.should == "us-east-1c"
  end

end
