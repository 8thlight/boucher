require 'boucher/compute'

module Boucher

  SNAPSHOT_TABLE_FORMAT = "%-13s  %-12s  %-18s  %-80s\n"

  def self.print_snapshots(volumes)
    puts
    printf SNAPSHOT_TABLE_FORMAT, "ID", "Volume ID", "Created At", "Description"
    puts ("-" * 120)

    volumes.each do |snapshot|
      printf SNAPSHOT_TABLE_FORMAT,
             snapshot.id,
             snapshot.volume_id,
             snapshot.created_at.strftime("%b %d %Y %H:%M"),
             snapshot.description[0...80]
    end
  end

  module Snapshots
    def self.all
      @snapshots ||= Boucher.compute.snapshots
    end

    def self.with_id(snapshot_id)
      all.find { |snapshot| snapshot.id == snapshot_id }
    end

    def self.snap(volume_id)
      description = "Boucher snapshot of #{volume_id} at #{Time.now.strftime("%b %d %Y %H:%M")}"
      snapshot = all.create(:volume_id => volume_id, :description => description)
      snapshot.wait_for { snapshot.state == "completed" }
      snapshot
    end

    #def self.destroy(volumes)
    #  Array(volumes).each do |snapshot|
    #    snapshot.reload
    #    snapshot.destroy
    #  end
    #end
    #
    #def self.with_id(volume_id)
    #  all.find { |snapshot| snapshot.id == volume_id }
    #end
    #
    #def self.create(options)
    #  zone = options[:availability_zone]
    #  raise ":availability_zone is required to create a snapshot." unless zone
    #  size = options[:size]
    #  snapshot_id = options[:snapshot_id]
    #  response = if snapshot_id
    #    snapshot = Boucher::compute.snapshots.get(snapshot_id)
    #    size = snapshot.volume_size.to_i
    #    Boucher.compute.create_volume(zone, size, "SnapshotId" => snapshot_id)
    #  else
    #    Boucher.compute.create_volume(zone, size)
    #  end
    #  volume_id = response.body["volumeId"]
    #  snapshot = Boucher.compute.volumes.get(volume_id)
    #  snapshot.wait_for { snapshot.ready? }
    #  snapshot
    #end
  end
end
