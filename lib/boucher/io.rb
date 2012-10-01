module Boucher

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
    if ENV["VERBOSE"]
      puts *args
    end
  end

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
    sorted_servers = servers.sort_by{|s| [s.tags["Env"] || "?",
                                          s.tags["Meal"] || "?"]}
    sorted_servers.each do |server|
      print_server(server) if server
    end
    puts
  end

  VOLUME_TABLE_FORMAT = "%-12s  %-15s  %-6s  %-10s  %-10s  %-13s\n"

  def self.print_volumes(volumes)
    puts
    printf VOLUME_TABLE_FORMAT, "ID", "Name", "Size", "Server", "State", "Snapshot"
    puts ("-" * 76)

    volumes.each do |volume|
      printf VOLUME_TABLE_FORMAT,
             volume.id,
             (volume.tags["Name"] || "")[0...15],
             volume.size.to_s + "GB",
             volume.server_id,
             volume.state,
             volume.snapshot_id
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
