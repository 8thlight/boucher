require 'boucher/volumes'
require 'boucher/io'

namespace :volumes do
  desc "List provisioned volumes"
  task :list do
    Boucher.print_volumes(Boucher::Volumes.all)
  end

  desc "Delete the specified volume"
  task :delete, [:volume_id] do |t, args|
    volume = Boucher::Volumes.with_id(args.volume_id)
    if volume
      puts "Deleting volume:"
      Boucher.print_volumes [volume]
      volume.destroy
      puts "The volume as been deleted."
    else
      raise "Volume not found: #{args.volume_id}"
    end
  end
end
