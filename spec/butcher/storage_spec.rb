require_relative "../spec_helper"
require 'butcher/storage'
require 'ostruct'

describe "Butcher Storage" do

  it "knows connections options" do
    connection = Butcher.storage
    connection.should_not == nil
    Butcher::S3_CONFIG[:aws_secret_access_key].should == Butcher::Config[:aws_secret_access_key]
    Butcher::S3_CONFIG[:aws_access_key_id].should == Butcher::Config[:aws_access_key_id]
  end

  context "with dir" do
    before do
      Butcher.storage.directories.create(:key => "test_bucket")
      File.open("test_file.txt", "w") { |f| f.write "wakka wakka" }
    end

    after do
      File.delete("test_file.txt") if File.exists?("test_file.txt")
      File.delete("test_file2.txt") if File.exists?("test_file2.txt")
    end

    it "puts a file" do
      Butcher::Storage.put("test_bucket", "test_file", "test_file.txt")
      dir = Butcher.storage.directories.get("test_bucket")
      file = dir.files.get("test_file")
      file.body.should == "wakka wakka"
    end

    it "gets a file" do
      Butcher::Storage.put("test_bucket", "test_file", "test_file.txt")
      time = Time.now
      Time.stub!(:now).and_return(time)
      Kernel.should_receive(:system) do |*args|
        args[0].should == "curl"
        args[1].should == Butcher.storage.directories.get("test_bucket").files.get_https_url("test_file", time + 3600)
        args[2].should == "-o"
        args[3].should == "test_file2.txt"
      end

      Butcher::Storage.get("test_bucket", "test_file", "test_file2.txt")
    end
  end

end
