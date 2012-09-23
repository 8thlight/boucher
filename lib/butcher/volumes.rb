require 'butcher/compute'

module Butcher
  def self.destroy_volume(volume_id)
    volume = Butcher::Volumes.with_id(volume_id)
    Volumes.destroy(volume)
  end

  module Volumes
    def self.all
      @volumes ||= Butcher.compute.volumes
    end

    def self.destroy(volumes)
      Array(volumes).each do |volume|
        volume.reload
        volume.destroy
      end
    end

    def self.with_id(volume_id)
      all.find {|volume| volume.id == volume_id}
    end

    def self.create(zone, snapshot, device)
      response  = Butcher.compute.create_volume(zone, snapshot.volume_size.to_i, snapshot.id)
      volume_id = response.body["volumeId"]
      volume    = Butcher.compute.volumes.get(volume_id)

      volume.wait_for { ready? }
      volume.device = device
      volume
    end

    def self.attach(volumes, server)
      Array(volumes).each do |volume|
        Butcher.compute.attach_volume(server.id, volume.id, volume.device)
      end
    end
  end
end
