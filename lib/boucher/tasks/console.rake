require 'boucher/compute'
require 'boucher/env'
require 'boucher/io'
require 'boucher/meals'
require 'boucher/provision'
require 'boucher/servers'
require 'boucher/volumes'
require 'boucher/nagios'

desc "Starts a console with the Boucher modules loaded"
task :console do
  require 'pry'

  Dir[File.expand_path("../../lib/boucher/**/*.rb", __FILE__)].each do |filename|
    require filename
  end

  include Boucher

  pry
end
