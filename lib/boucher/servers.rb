require 'boucher/compute'

module Boucher

  SERVER_TABLE_FORMAT = "%-12s  %-12s  %-10s  %-10s  %-10s  %-15s  %-15s %-10s\n"

  def self.print_server_table_header
    puts
    printf SERVER_TABLE_FORMAT, "ID", "Environment", "Meal", "Creator", "State", "Public IP", "Private IP", "Inst. Size"
    puts ("-" * 120)
  end

  def self.print_server(server)
    printf SERVER_TABLE_FORMAT,
           server.id,
           (server.tags["Env"] || "???")[0...12],
           (server.tags["Meal"] || "???")[0...10],
           (server.tags["Creator"] || "???")[0...10],
           server.state,
           server.public_ip_address,
           server.private_ip_address,
           server.flavor_id
  end

  def self.print_servers(servers)
    print_server_table_header
    sorted_servers = servers.sort_by { |s| [s.tags["Env"] || "?",
                                            s.tags["Meal"] || "?"] }
    sorted_servers.each do |server|
      print_server(server) if server
    end
    puts
  end

  module Servers
    NotFound = Class.new(StandardError)

    class << self
      def clear
        @instance = nil
      end

      def instance
        reload if !@instance
        @instance
      end

      def reload
        @instance = Boucher.compute.servers
        @instance.each {} # Wake up you lazy list!
        cultivate(@instance)
      end

      %w{all of_meal in_env in_state search find [] with_id}.each do |m|
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
      servers = servers.of_meal(options[:meal]) if options[:meal]
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
      Servers.cultivate(self.find_all { |s| s.tags["Env"] == env.to_s })
    end

    def in_state(state)
      if state[0] == "!"
        state = state[1..-1]
        Servers.cultivate(self.find_all { |s| s.state != state.to_s })
      else
        Servers.cultivate(self.find_all { |s| s.state == state.to_s })
      end
    end

    def of_meal(meal)
      Servers.cultivate(self.find_all { |s| s.tags["Meal"] == meal.to_s })
    end

    def self.start(servers)
      Boucher.change_servers_state(servers, :start, "running")
    end

    def self.stop(servers)
      Boucher.change_servers_state(servers, :stop, "stopped")
    end

    def self.restart(servers)
      Boucher.change_servers_state(servers, :stop, "stopped")
      Boucher.change_servers_state(servers, :start, "running")
    end

    def self.terminate(servers)
      Boucher.change_servers_state(servers, :destroy, "terminated")
    end

    def with_id(server_id)
      Servers.cultivate(self.find_all { |s| s.id == server_id }).first
    end

    def [](meal)
      find(:env => Boucher::Config[:env], :meal => meal, :state => "running")
    end
  end

  def self.change_servers_state(servers, command, new_state)
    print "#{command}-ing servers #{servers.map(&:id).join(", ")}..."
    servers.each { |s| s.send(command.to_sym) }
    servers.each { |s| s.wait_for { print "."; s.state == new_state }}
    puts
    Boucher.print_servers servers
    puts
    puts "The servers have been #{command}-ed."
  end
end
