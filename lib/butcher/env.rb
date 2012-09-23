module Butcher

  Config = {
          :branch => ENV["BRANCH"] || "master"
  } unless defined?(Butcher::Config)

  def self.env_name
    ENV["BUTCHER_ENV"] ? ENV["BUTCHER_ENV"] : :dev
  end

  env_dir = File.expand_path("config/env")
  valid_envs = Dir[File.join(env_dir, "**", "*.rb")].map { |path| File.basename(path, ".rb") }
  env_path = File.expand_path("#{env_name}.rb", env_dir)

  unless defined?(Butcher::NO_LOAD_CONFIG)
    unless File.exists?(env_path)
      raise "Config file #{env_path} doesn't exist.\nYou need to change your BUTCHER_ENV environment variable to a valid environment name.\nValid environments: #{valid_envs.join(", ")}"
    end

    load env_path
  end

  def self.force_env!(name)
    env = name.to_sym
    Butcher::Config[:branch] = ENV["BRANCH"] || "master"
    load File.expand_path(File.dirname(__FILE__) + "/../../config/env/shared.rb") unless defined?(Butcher::NO_LOAD_CONFIG)
    file = File.expand_path(File.dirname(__FILE__) + "/../../config/env/#{env}.rb")
    unless defined?(Butcher::NO_LOAD_CONFIG)
      if File.exist?(file)
        load file
      else
        require_relative "../../config/env/shared"
      end
    end
  end

  def self.assert_env!
    unless ENV['BUTCHER_ENV']
      raise 'BUTCHER_ENV must be set before running this command'
    end

    unless ENV['BRANCH']
      raise 'BRANCH must be set before running this command'
    end
  end
end
