require 'boucher/storage'
require 'boucher/io'

namespace :storage do

  desc "Lists all the files in the infrastructure bucket on S3"
  task :list, [:path] do |t, args|
    puts "Listing files: #{args.path || "/"} ..."
    files = Boucher::Storage.list(args.path)
    Boucher.print_files files
  end

  desc "Puts a file in the infrastructure bucket"
  task :put, [:file, :path] do |t, args|
    filename = args.file
    bucket, key = args.path.split("/")
    puts "Storing file #{filename} as #{bucket}/#{key}"
    file = Boucher::Storage.put(bucket, key, filename)
    Boucher.print_files [file]
    puts "File uploaded as #{bucket}/#{key}."
  end

  desc "Downloads a file from S3. The path should be <bucket_name>/<file_key>."
  task :get, [:path] do |t, args|
    directory, filename = args.path.split("/")
    raise "Path must be of the form <bucket_name>/<file_key>" unless (directory && filename)
    puts "Getting file #{args.path} and saving to ./#{filename}"
    file = Boucher::Storage.get(directory, filename, filename)
    Boucher.print_files [file]
    puts "File saved locally as #{filename}."
  end

end