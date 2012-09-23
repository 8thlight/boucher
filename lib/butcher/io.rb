module Butcher

  module IO

    def self.mock!
      $stdout = StringIO.new
      $stderr = StringIO.new
      $stdin = StringIO.new
    end

    def self.real!
      $stdout = STDOUT
      $stderr = STDERR
      $stdin = STDIN
    end

  end

  def self.verbose(*args)
    if ENV["VERBOSE"] != "false"
      puts *args
    end
  end

  SERVER_TABLE_FORMAT = "%-12s  %-12s  %-10s  %-10s  %-10s  %-15s  %-15s %-10s\n"

  def self.print_server_table_header
    puts
    printf SERVER_TABLE_FORMAT, "ID", "Environment", "Class", "Creator", "State", "Public IP", "Private IP", "Inst. Size"
    puts ("-" * 120)
  end

  def self.print_server(server)
    printf SERVER_TABLE_FORMAT,
           server.id,
           (server.tags["Env"] || "???")[0...12],
           (server.tags["Class"] || "???")[0...10],
           (server.tags["Creator"] || "???")[0...10],
           server.state,
           server.public_ip_address,
           server.private_ip_address,
           server.flavor_id
  end

  def self.print_servers(servers)
    print_server_table_header
    sorted_servers = servers.sort_by{|s| [s.tags["Env"] || "?",
                                          s.tags["Class"] || "?"]}
    sorted_servers.each do |server|
      print_server(server) if server
    end
    puts
  end

  def self.print_volumes(volumes)
    id_sizes = []
    size_sizes = []
    state_sizes = []
    zone_sizes = []
    snapshot_sizes = []

    Array(volumes).each do |volume|
      id_sizes << volume.id.length
      size_sizes << volume.size.to_s.length
      state_sizes << volume.state.length
      zone_sizes << volume.availability_zone.length
      snapshot_sizes << volume.snapshot_id.to_s.length
    end

    id_length = id_sizes.max + 5
    size_length = size_sizes.max + 5
    state_length = state_sizes.max + 5
    zone_length = zone_sizes.max + 5
    snapshot_length = snapshot_sizes.max

    puts "ID#{" "*(id_length - 2)}Size#{" "*(size_length - 4)}State#{" "*(state_length - 5)}Zone#{" "*(zone_length - 4)}Snapshot"
    puts "-"*(id_length + size_length + state_length + zone_length + snapshot_length)

    Array(volumes).each do |volume|
      puts "#{volume.id}#{" "*(id_length - volume.id.length)}#{volume.size}GB#{" "*(size_length - volume.size.to_s.length - 2)}#{volume.state}#{" "*(state_length - volume.state.length)}#{volume.availability_zone}#{" "*(zone_length - volume.availability_zone.length)}#{volume.snapshot_id}#{" "*(snapshot_length - volume.snapshot_id.to_s.length)}"
    end
  end

  FILE_TABLE_FORMAT = "%-60s  %-10s  %-25s  %-32s\n"

  def self.print_file_table_header
    puts
    printf FILE_TABLE_FORMAT, "Key", "Size", "Last Modified", "etag"
    puts ("-" * 150)
  end

  def self.print_file(file)
    printf FILE_TABLE_FORMAT,
           file.key,
           file.content_length,
           file.last_modified,
           file.etag
  end

  def self.print_files(files)
    print_file_table_header
    files.each do |file|
      print_file(file) if file
    end
    puts
  end

end
