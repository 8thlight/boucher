require 'boucher/volumes'
require 'boucher/io'

namespace :volumes do
  desc "List provisioned volumes"
  task :list do
    Boucher.print_volumes(Boucher::Volumes.all)
  end

  desc "Destroy the specified volume"
  task :destroy, [:volume_id] do |t, args|
    Boucher.destroy_volume(args.volume_id)
  end
end
