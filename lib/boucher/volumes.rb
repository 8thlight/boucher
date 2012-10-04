require 'boucher/compute'

module Boucher

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

  module Volumes
    def self.all
      @volumes ||= Boucher.compute.volumes
    end

    def self.destroy(volumes)
      Array(volumes).each do |volume|
        volume.reload
        volume.destroy
      end
    end

    def self.with_id(volume_id)
      all.find { |volume| volume.id == volume_id }
    end

    def self.create(options)
      zone = options[:availability_zone]
      raise ":availability_zone is required to create a volume." unless zone
      size = options[:size]
      snapshot_id = options[:snapshot_id]
      response = if snapshot_id
        snapshot = Boucher::compute.snapshots.get(snapshot_id)
        size = snapshot.volume_size.to_i
        Boucher.compute.create_volume(zone, size, "SnapshotId" => snapshot_id)
      else
        Boucher.compute.create_volume(zone, size)
      end
      volume_id = response.body["volumeId"]
      volume = Boucher.compute.volumes.get(volume_id)
      volume.wait_for { volume.ready? }
      volume
    end
  end
end
