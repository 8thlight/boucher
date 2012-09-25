module Boucher
  module CI
    def self.each_server(&block)
      threads = []
      Boucher.each_required_server do |server, server_class|
        thread = Thread.new { block.yield(server, server_class) }
        threads << thread
      end
      threads.each { |t| t.join }
    end

    def self.terminate_server(server_class)
      server = Boucher.get_server(server_class, "ci", "running")
      Boucher.change_server_state server.id, :destroy, "terminated" if server
    end
  end
end

