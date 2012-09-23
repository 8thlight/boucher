require_relative "../spec_helper"
require 'butcher/classes'
require 'ostruct'

describe "Butcher Server Classes" do

  before do
    Butcher.stub(:current_user).and_return("joe")
    @server = OpenStruct.new
  end

  it "pull classification from json" do
    json = "{\"butcher\": {\"foo\": 1,\n \"bar\": 2}}"
    Butcher.json_to_class(json).should == {:foo => 1, :bar => 2}
  end

  it "can classify base server" do
    some_class = {:class_name => "base",
                  :meals => ["base"]}
    Butcher.classify(@server, some_class)

    @server.image_id.should == Butcher::Config[:base_image_id]
    @server.flavor_id.should == 'm1.small'
    @server.groups.should == ["SSH"]
    @server.key_name.should == "test_key"
    @server.tags["Class"].should == "base"
    @server.tags["Name"].should_not == nil
    @server.tags["Creator"].should == "joe"
    @server.tags["Env"].should == Butcher::Config[:env]
  end

end

