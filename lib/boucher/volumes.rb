require 'boucher/compute'

module Boucher
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
