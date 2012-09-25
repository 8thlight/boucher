require_relative "../spec_helper"
require "boucher/io"
require 'ostruct'

describe "Boucher IO" do

  before do
    Boucher::IO.mock!
  end

  it "prints server table header" do
    Boucher.print_server_table_header

    output = $stdout.string
    puts "output: #{output}"
    %w{ID Env Class Creator State Public IP Private IP}.each do |header|
      output.should include(header)
    end
  end

  it "prints a server" do
    server = OpenStruct.new(
            :id => "test_id",
            :tags => {"Env" => "test_env", "Class" => "test_class", "Creator" => "Joe"},
            :state => "test_state",
            :public_ip_address => "1.2.3.4")

    Boucher.print_server server
    output = $stdout.string

    output.should include("test_id")
    output.should include("test_")
    output.should include("test_class")
    output.should include("Joe")
    output.should include("test_state")
    output.should include("1.2.3.4")
  end

  it "prints servers ordered by Env, then Class" do
    server_1 = OpenStruct.new(
              :id => "test_id_1",
              :tags => {"Env" => "test_env", "Class" => "test_class", "Creator" => "Joe"},
              :state => "test_state",
              :public_ip_address => "1.2.3.4")

    server_2 = OpenStruct.new(
              :id => "test_id_2",
              :tags => {"Env" => "better_env", "Class" => "test_class_1", "Creator" => "Joe"},
              :state => "test_state",
              :public_ip_address => "1.2.3.5")

    server_3 = OpenStruct.new(
              :id => "test_id_3",
              :tags => {"Env" => "better_env", "Class" => "test_class_2", "Creator" => "Joe"},
              :state => "test_state",
              :public_ip_address => "1.2.3.6")

    Boucher.print_servers([server_1, server_2, server_3])
    output = $stdout.string

    lines = output.split("\n")
    lines[0].should == ""
    lines[2].should include("------")
    lines[3].should include("test_id_2")
    lines[4].should include("test_id_3")
    lines[5].should include("test_id_1")
  end
end
