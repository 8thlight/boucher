require 'boucher/snapshots'

namespace :snapshots do
  desc "List all snapshots"
  task :list do
    Boucher.print_snapshots(Boucher::Snapshots.all)
  end

  desc "Takes a snapshot of the specified volume"
  task :snap, [:volume_id] do |t, args|
    puts "Taking snapshot of volume #{args.volume_id}"
    snapshot = Boucher::Snapshots.snap(args.volume_id)
    Boucher.print_snapshots [snapshot]
  end

  desc "Deleted the specified snapshot"
  task :delete, [:snapshot_id] do |t, args|
    snapshot = Boucher::Snapshots.with_id(args.snapshot_id)
    if snapshot
      puts "Deleting snapshot:"
      Boucher.print_snapshots [snapshot]
      snapshot.destroy
      puts "The snapshot as been deleted."
    else
      raise "Snapshot not found: #{args.snapshot_id}"
    end
  end
end
