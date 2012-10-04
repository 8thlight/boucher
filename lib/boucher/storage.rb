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

  FILE_TABLE_FORMAT = "%-60s  %-10s  %-25s  %-32s\n"

  def self.print_file_table_header
    puts
    printf FILE_TABLE_FORMAT, "Key", "Size", "Last Modified", "etag"
    puts ("-" * 150)
  end

  def self.print_file(file)
    printf FILE_TABLE_FORMAT,
           file.key,
           file.content_length,
           file.last_modified,
           file.etag
  end

  def self.print_files(files)
    print_file_table_header
    files.each do |file|
      print_file(file) if file
    end
    puts
  end

  module Storage

    def self.list(dir_name)
      dir = Boucher.storage.directories.get(dir_name)
      result = dir.files.select { |f| f.key[-1] != "/" }.to_a
      result
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
      Kernel.system("curl", url, "-o", filename)
      dir.files.detect { |f| f.key == key }
    end

  end
end
