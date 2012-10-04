module Boucher

  module IO

    def self.mock!
      $stdout = StringIO.new
      $stderr = StringIO.new
      $stdin = StringIO.new
    end

    def self.real!
      $stdout = STDOUT
      $stderr = STDERR
      $stdin = STDIN
    end

  end

  def self.verbose(*args)
    if ENV["VERBOSE"]
      puts *args
    end
  end

end
