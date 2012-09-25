require 'boucher/env'
require 'boucher/util'
require 'json'

module Boucher

  def self.json_to_class(json)
    parser = JSON.parser.new(json, :symbolize_names => true)
    config = parser.parse
    config[:boucher]
  end

  def self.server_classes
    if @server_classes.nil?
      @server_classes = {}
      Dir.glob(File.join("config", "*.json")).each do |file|
        spec = json_to_class(IO.read(file))
        class_name = File.basename(file).to_sym
        @server_classes[class_name] = spec
      end
    end
    @server_classes
  end

  def self.classify(server, class_spec)
    server.image_id = class_spec[:base_image_id] || Boucher::Config[:base_image_id]
    server.flavor_id = class_spec[:flavor_id] || Boucher::Config[:default_instance_flavor_id]
    server.groups = class_spec[:groups] || Boucher::Config[:default_instance_groups]
    server.key_name = class_spec[:key_name] || Boucher::Config[:aws_key_filename]
    server.tags = {}
    server.tags["Name"] = "#{class_spec[:class_name] || "base"} #{Time.new.strftime("%Y%m%d%H%M%S")}"
    server.tags["Class"] = class_spec[:class_name] || "base"
    server.tags["CreatedAt"] = Time.new.strftime("%Y%m%d%H%M%S")
    server.tags["Creator"] = current_user
    server.tags["Env"] = Boucher::Config[:env]
    server.tags["Volumes"] = class_spec[:volumes]
  end

end
