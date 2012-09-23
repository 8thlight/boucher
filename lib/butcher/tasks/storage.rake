require 'butcher/storage'
require 'butcher/io'

namespace :storage do

  desc "Lists all the files in the infrastructure bucket on S3"
  task :list do
    files = Butcher::Storage.list("infrastructure")
    Butcher.print_files files
  end

  desc "Puts a file in the infrastructure bucket"
  task :put, [:file] do |t, args|
    filename = args.file
    key = File.basename(filename)
    puts "Storing file #{filename} as #{key}"
    file = Butcher::Storage.put("infrastructure", key, filename)
    Butcher.print_files [file]
    puts "File uploaded as #{key}."
  end

  desc "Gets a file from the infrastructure bucket. The file arg is the key on AWS."
  task :get, [:file] do |t, args|
    key = args.file
    filename = File.basename(key)
    puts "Getting file #{key} and saving to #{filename}"
    file = Butcher::Storage.get("infrastructure", key, filename)
    Butcher.print_files [file]
    puts "File saved locally as #{filename}."
  end

end