# -*- encoding: utf-8 -*-
require File.expand_path('../lib/resque/plugins/timed_round_robin/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Eddy Kim", "Ben Schmeckpeper"]
  gem.email         = ["eddyhkim@gmail.com", "ben.schmeckpeper@gmail.com"]
  gem.description   = %q{A Resque round-robin plugin, with time based rotation}
  gem.summary       = %q{A Resque plugin to modify the worker behavior to pull jobs off queues, working a queue for a specified amount of time before rotating}
  gem.homepage      = ""

  gem.add_dependency "resque", ">= 1.25", "< 3.0"

  gem.add_development_dependency('rspec', '~> 2.5')
  gem.add_development_dependency('rack-test', '~> 0.5.4')
  gem.add_development_dependency('timecop')

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "resque-timed-round-robin"
  gem.require_paths = ["lib"]
  gem.version       = Resque::Plugins::TimedRoundRobin::VERSION
end
