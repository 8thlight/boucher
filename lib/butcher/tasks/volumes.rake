require 'butcher/volumes'
require 'butcher/io'

namespace :volumes do
  desc "List provisioned volumes"
  task :list do
    Butcher.print_volumes(Butcher::Volumes.all)
  end

  desc "Destroy the specified volume"
  task :destroy, [:volume_id] do |t, args|
    Butcher.destroy_volume(args.volume_id)
  end
end
