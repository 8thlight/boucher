# MDM - Need to set config because it's never loaded in test
module Boucher
  NO_LOAD_CONFIG = true
  Config = {
          :aws_secret_access_key => "secret key",
          :aws_access_key_id => "public id",
          :aws_key_filename => "test_key"
  }
end

require 'fog'
require 'boucher/io'
require 'boucher/env'

Boucher.force_env!("dev")

Fog.mock!
Boucher::IO.mock!

# MDM - Monkey patch wait_for methods so the tests are FASTER!
# Unfortunately, Fog mocks depends on real time delays :.-(
#module Fog
#  def self.wait_for(timeout=Fog.timeout, interval=1)
#    yield
#  end
#end

#require 'fog/core/model'
#
#module Fog
#  class Model
#    def wait_for(timeout=Fog.timeout, interval=1, &block)
#      yield
#    end
#  end
#end
