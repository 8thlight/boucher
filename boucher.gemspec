# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "boucher"
  s.version     = "0.3.1"
  s.authors     = ["'Micah Micah'"]
  s.email       = ["'micah@8thlight.com'"]
  s.homepage    = "http://github.com/8thlight/boucher"
  s.summary     = "AWS system deployment and management"
  s.description = "AWS system deployment and management"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = []
  s.require_paths = ["lib"]

  s.add_dependency('rake', '>= 0.9.2.2')
  s.add_dependency('fog', '>= 1.27.0')
  s.add_dependency('retryable', '>= 1.3.1')
  s.add_dependency('pry', '>= 0.9.10')
end
