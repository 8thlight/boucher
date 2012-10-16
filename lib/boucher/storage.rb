require 'boucher/env'
require 'boucher/meals'
require 'fog'

module Boucher

  S3_CONFIG = {
          :provider => 'AWS',
          :aws_secret_access_key => Boucher::Config[:aws_secret_access_key],
          :aws_access_key_id => Boucher::Config[:aws_access_key_id]
  }

  def self.storage
    @store ||= Fog::Storage.new(S3_CONFIG)
    @store
  end

  FILE_TABLE_FORMAT = "%-4s  %-60s  %-10s  %-25s  %-32s\n"

  def self.print_file_table_header
    puts
    printf FILE_TABLE_FORMAT, "Type", "Key", "Size", "Last Modified", "etag"
    puts ("-" * 156)
  end

  def self.print_file(file)
    printf FILE_TABLE_FORMAT,
           "file",
           file.key,
           file.content_length,
           file.last_modified,
           file.etag
  end

  def self.print_directory(directory)
    printf FILE_TABLE_FORMAT,
           "dir",
           directory.key,
           "",
           directory.creation_date,
           ""
  end

  def self.print_files(files)
    print_file_table_header
    files.each do |file|
      if file
        if file.class.name =~ /Directory/
          print_directory(file)
        else
          print_file(file)
        end
      end
    end
    puts
  end

  module Storage

    def self.dir(dir_name)
      Boucher.storage.directories.get(dir_name)
    rescue Exception => e
      raise "Failed to access directory: #{dir_name} (#{e.to_s})"
    end

    def self.list(dir_name)
      if dir_name
        dir(dir_name).files
      else
        Boucher.storage.directories
      end
    end

    def self.put(dir_name, key, filename)
      dir = Boucher.storage.directories.get(dir_name)
      body = File.open(filename)
      file = dir.files.new(:key => key, :body => body)
      file.save
      body.close
      file
    end

    def self.get(dir_name, key, filename)
      dir = Boucher.storage.directories.get(dir_name)
      url = dir.files.get_https_url(key, Time.now + 3600)
      puts "url: #{url}"
      Kernel.system("curl", url, "-o", filename)
      dir.files.detect { |f| f.key == key }
    end

  end
end
