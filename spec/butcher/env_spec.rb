require 'spec_helper'

describe "Environment" do
  describe "env" do
    before do
      @old_env = ENV['BUTCHER_ENV']
    end

    after do
      ENV['BUTCHER_ENV'] = @old_env
    end

    it "defaults to :dev" do
      ENV.delete('BUTCHER_ENV')
      #load File.expand_path(File.dirname(__FILE__) + "/../../lib/butcher/env.rb")
      Butcher::env_name.should == :dev
    end

    it "can be set via an environment variable" do
      ENV['BUTCHER_ENV'] = "ci"
      load File.expand_path(File.dirname(__FILE__) + "/../../lib/butcher/env.rb")
      Butcher::env_name.should == "ci"
    end
  end

  describe "branch" do
    before do
      @old_branch = ENV['BRANCH']
      ENV.delete('BRANCH')
    end

    after do
      ENV['BRANCH'] = @old_branch
    end

    it "defaults to master" do
      Butcher.force_env!(:dev)
      Butcher::Config[:branch].should == "master"
    end

    it "can be set via an environment variable" do
      ENV['BRANCH'] = "some_branch"
      Butcher.force_env!(:dev)
      Butcher::Config[:branch].should == "some_branch"
    end
  end
end
