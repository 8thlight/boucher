
task_dir = File.expand_path(File.join(File.dirname(__FILE__), "tasks"))

Dir.glob(File.join(task_dir, "*.rake")).each do |lib|
  load lib
end