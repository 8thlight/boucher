require 'boucher/env'
require 'boucher/util'
require 'erb'
require 'json'

module Boucher

  def self.json_to_meal(json)
    template = ERB.new(json)
    json = template.result(binding)
    parser = JSON.parser.new(json, :symbolize_names => true)
    config = parser.parse
    config[:boucher] || {}
  end

  def self.meals
    if @meals.nil?
      @meals = {}
      Dir.glob(File.join("config", "*.json")).each do |file|
        spec = json_to_meal(::IO.read(file))
        meal_name = File.basename(file)[0...-5].to_sym
        @meals[meal_name] = spec.merge(:name => meal_name)
      end
    end
    @meals
  end

  def self.meal(meal_name)
    the_meal = meals[meal_name.to_sym]
    raise "Missing meal: #{meal_name}" unless the_meal
    return the_meal
  end

  def self.setup_meal(server, meal)
    server.image_id = meal[:image_id] || Boucher::Config[:default_image_id]
    server.flavor_id = meal[:flavor_id] || Boucher::Config[:default_flavor_id]
    server.groups = meal[:groups] || Boucher::Config[:default_groups]
    server.key_name = meal[:key_name] || Boucher::Config[:aws_key_filename]
    server.tags = {}
    server.tags["Name"] = "#{meal[:name] || "base"} #{Time.new.strftime("%Y%m%d%H%M%S")}"
    server.tags["Meal"] = meal[:name] || "base"
    server.tags["CreatedAt"] = Time.new.strftime("%Y%m%d%H%M%S")
    server.tags["Creator"] = current_user
    server.tags["Env"] = Boucher::Config[:env]
  end

end
