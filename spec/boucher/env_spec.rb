require 'spec_helper'

describe "Environment" do
  describe "env" do
    before do
      @old_env = ENV['BENV']
    end

    after do
      ENV['BENV'] = @old_env
    end

    it "defaults to :dev" do
      Boucher::Config.delete(:env)
      ENV.delete('BENV')
      #load File.expand_path(File.dirname(__FILE__) + "/../../lib/boucher/env.rb")
      Boucher::env_name.should == :dev
    end

    it "can be set via an environment variable" do
      ENV['BENV'] = "ci"
      load File.expand_path(File.dirname(__FILE__) + "/../../lib/boucher/env.rb")
      Boucher::env_name.should == "ci"
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
      Boucher.force_env!(:dev)
      Boucher::Config[:branch].should == "master"
    end

    it "can be set via an environment variable" do
      ENV['BRANCH'] = "some_branch"
      Boucher.force_env!(:dev)
      Boucher::Config[:branch].should == "some_branch"
    end
  end
end
