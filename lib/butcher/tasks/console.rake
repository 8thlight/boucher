require 'butcher/compute'
require 'butcher/env'
require 'butcher/io'
require 'butcher/classes'
require 'butcher/provision'
require 'butcher/servers'
require 'butcher/volumes'
require 'butcher/nagios'

desc "Starts a console with the Butcher modules loaded"
task :console do
  require 'pry'

  Dir[File.expand_path("../../lib/butcher/**/*.rb", __FILE__)].each do |filename|
    require filename
  end

  include Butcher

  pry
end
