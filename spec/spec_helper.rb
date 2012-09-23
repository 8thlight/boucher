# MDM - Need to set config because it's never loaded in test
module Butcher
  NO_LOAD_CONFIG = true
  Config = {
          :aws_secret_access_key => "secret key",
          :aws_access_key_id => "public id",
          :aws_key_filename => "test_key"
  }
end

require 'fog'
require 'butcher/io'
require 'butcher/env'

Butcher.force_env!("dev")

Fog.mock!
Butcher::IO.mock!


# MDM - Monkey patch wait_for methods so the tests are FASTER!
module Fog
  def self.wait_for(timeout=Fog.timeout, interval=1)
    yield
  end
end

require 'fog/core/model'

module Fog
  class Model
    def wait_for(timeout=Fog.timeout, interval=1, &block)
      yield
    end
  end
end
