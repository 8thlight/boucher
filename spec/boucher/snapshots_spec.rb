require_relative "../spec_helper"
require 'boucher/snapshots'
require 'boucher/volumes'

describe "Boucher::snapshots" do

  context "with mocked volumes" do
    let(:remote_snapshots) {
      [OpenStruct.new(:id => "snap-1", :tags => {}, :description => "1"),
       OpenStruct.new(:id => "snap-2", :tags => {}, :description => "2"),
       OpenStruct.new(:id => "snap-3", :tags => {}, :description => "3")]
    }

    before do
      Boucher.compute.stub(:snapshots).and_return(remote_snapshots)
    end

    after do
      Boucher::Config[:env] = "test"
    end

    it "finds all snapshots" do
      Boucher::Snapshots.instance_variable_set(:@snapshots, nil)
      Boucher::Snapshots.all.size.should == 3
      Boucher::Snapshots.all.should == remote_snapshots
    end
  end

  it "takes a snapshot" do
    volume = Boucher::Volumes.create(:size => 12, :availability_zone => "us-east-1c")
    snapshot = Boucher::Snapshots.snap(volume.id)

    snapshot.volume_id.should == volume.id
    snapshot.state.should == "completed"
    snapshot.description[0...16].should == "Boucher snapshot"
  end
end
