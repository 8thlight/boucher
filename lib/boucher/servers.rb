require 'boucher/compute'

module Boucher
  module Servers
    NotFound = Class.new(StandardError)

    class << self
      def instance
        reload if !@instance
        @instance
      end

      def reload
        @instance = Boucher.compute.servers
        @instance.each {} # Wake up you lazy list!
        cultivate(@instance)
      end

      %w{all of_class in_env in_state search find [] with_id}.each do |m|
        module_eval "def #{m}(*args); instance.#{m}(*args); end"
      end

      def cultivate(thing)
        thing.extend(Boucher::Servers) if thing
        thing
      end
    end

    def all
      self
    end

    def search(options={})
      servers = self
      servers = servers.of_class(options[:class]) if options[:class]
      servers = servers.in_env(options[:env]) if options[:env]
      servers = servers.in_state(options[:state]) if options[:state]
      servers
    end

    def find(options={})
      servers = search(options)
      first = servers.first
      if first.nil?
        raise Boucher::Servers::NotFound.new("No server matches criteria: #{options.inspect}")
      end
      first
    end

    def in_env(env)
      Servers.cultivate(self.find_all {|s| s.tags["Env"] == env.to_s })
    end

    def in_state(state)
      Servers.cultivate(self.find_all {|s| s.state == state.to_s })
    end

    def of_class(klass)
      Servers.cultivate(self.find_all {|s| s.tags["Class"] == klass.to_s })
    end

    def self.start(server_id)
      Boucher.change_server_state(server_id, :start, "running")
    end

    def self.stop(server_id)
      Boucher.change_server_state(server_id, :stop, "stopped")
    end

    def self.terminate(server)
      Boucher::Nagios.remove_host(server)
      volumes = server.volumes
      volumes_to_destroy = volumes.select {|v| !v.delete_on_termination}

      Boucher.change_server_state server.id, :destroy, "terminated"

      volumes_to_destroy.each do |volume|
        volume.wait_for { volume.state == 'available' }
        puts "Destroying volume #{volume.id}..."
        Boucher::Volumes.destroy(volume)
      end
    end

    def with_id(server_id)
      Servers.cultivate(self.find_all {|s| s.id == server_id}).first
    end

    def [](klass)
      find(:env => Boucher::Config[:env], :class => klass, :state => "running")
    end
  end
end
