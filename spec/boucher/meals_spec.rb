require_relative "../spec_helper"
require 'boucher/meals'
require 'ostruct'

describe "Boucher Server Meals" do

  before do
    Boucher.stub(:current_user).and_return("joe")
    @server = OpenStruct.new
  end

  it "pull classification from json" do
    json = "{\"boucher\": {\"foo\": 1,\n \"bar\": 2}}"
    Boucher.json_to_meal(json).should == {:foo => 1, :bar => 2}
  end

  it "can classify base server" do
    some_class = {:meal_name => "base",
                  :meals => ["base"]}
    Boucher::Config[:default_instance_flavor_id] = 'm1.small'
    Boucher::Config[:default_instance_groups] = ["SSH"]
    Boucher.setup_meal(@server, some_class)

    @server.image_id.should == Boucher::Config[:base_image_id]
    @server.flavor_id.should == 'm1.small'
    @server.groups.should == ["SSH"]
    @server.key_name.should == "test_key"
    @server.tags["Meal"].should == "base"
    @server.tags["Name"].should_not == nil
    @server.tags["Creator"].should == "joe"
    @server.tags["Env"].should == Boucher::Config[:env]
  end

end

